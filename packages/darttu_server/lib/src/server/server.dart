import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../database/database.dart';
import '../repositories/auth.dart';
import '../repositories/rooms.dart';
import '../services/auth.dart';
import '../services/rooms.dart';

final class Server {
  final AppDatabase _database;
  late final DriftRoomsRepo _roomsRepo;
  late final AuthService _authService;
  late final RoomsService _roomsService;
  final Set<_SocketSession> _sessions = <_SocketSession>{};
  HttpServer? _httpServer;

  Server({String databasePath = 'darttu_server.sqlite'})
    : _database = AppDatabase(databasePath) {
    final authRepo = DriftAuthRepo(database: _database);
    final roomsRepo = DriftRoomsRepo(database: _database);
    _roomsRepo = roomsRepo;
    _authService = AuthService(repo: authRepo);
    _roomsService = RoomsService(authRepo: authRepo, roomsRepo: roomsRepo);
  }

  Future<HttpServer> serve({String host = '0.0.0.0', int port = 8080}) async {
    final server = await HttpServer.bind(host, port);
    _httpServer = server;
    unawaited(_listen(server));
    return server;
  }

  Future<void> close() async {
    for (final session in _sessions.toList(growable: false)) {
      await session.socket.close();
    }
    await _httpServer?.close(force: true);
    await _database.closeConnection();
  }

  Future<void> _listen(HttpServer server) async {
    await for (final request in server) {
      final startedAt = DateTime.now();
      stdout.writeln(
        '[${startedAt.toIso8601String()}] -> ${request.method} ${request.uri.path}',
      );

      try {
        if (request.uri.path == '/health') {
          _writeJsonResponse(request.response, 200, {'status': 'ok'});
          continue;
        }

        if (request.uri.path == '/ws' && WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          final session = _SocketSession(socket: socket);
          _sessions.add(session);
          unawaited(_handleSocket(session));
          continue;
        }

        _writeJsonResponse(request.response, 404, {'error': 'not_found'});
      } on Object catch (error, stackTrace) {
        stdout.writeln(
          '[${DateTime.now().toIso8601String()}] !! ${request.method} ${request.uri.path} failed: $error',
        );
        stderr.writeln(stackTrace);
        try {
          _writeJsonResponse(request.response, 500, {'error': 'internal_server_error'});
        } on Object {
          await request.response.close();
        }
      }
    }
  }

  Future<void> _handleSocket(_SocketSession session) async {
    try {
      await for (final message in session.socket) {
        if (message is! String) {
          continue;
        }

        await _handleSocketMessage(session, message);
      }
    } finally {
      _sessions.remove(session);
      if (session.userId != null) {
        await _roomsRepo.disconnectUser(session.userId!);
      }
    }
  }

  Future<void> _handleSocketMessage(_SocketSession session, String message) async {
    Map<String, Object?> decoded;
    try {
      final json = jsonDecode(message);
      if (json is! Map<String, Object?>) {
        throw const FormatException('invalid_message');
      }
      decoded = json;
    } on Object {
      _sendSocketResponse(
        session.socket,
        requestId: null,
        statusCode: 400,
        body: {'error': 'invalid_message'},
      );
      return;
    }

    final requestId = decoded['requestId']?.toString();
    final action = decoded['action']?.toString() ?? '';
    final payload = decoded['payload'];
    final data = payload is Map<String, Object?> ? payload : <String, Object?>{};

    switch (action) {
      case 'ping':
        _sendSocketResponse(
          session.socket,
          requestId: requestId,
          statusCode: 200,
          body: {'ok': true},
        );
        return;
      case 'signup':
        final result = await _authService.signup(
          username: data['username']?.toString() ?? '',
          password: data['password']?.toString() ?? '',
        );
        await _applyAuthResult(session, result);
        _sendSocketResponse(
          session.socket,
          requestId: requestId,
          statusCode: result.statusCode,
          body: result.body,
        );
        return;
      case 'login':
        final result = await _authService.login(
          username: data['username']?.toString() ?? '',
          password: data['password']?.toString() ?? '',
        );
        await _applyAuthResult(session, result);
        _sendSocketResponse(
          session.socket,
          requestId: requestId,
          statusCode: result.statusCode,
          body: result.body,
        );
        return;
      case 'session':
        final result = await _authService.session(
          data['sessionToken']?.toString() ?? '',
        );
        await _applyAuthResult(session, result);
        _sendSocketResponse(
          session.socket,
          requestId: requestId,
          statusCode: result.statusCode,
          body: result.body,
        );
        return;
      case 'lobby':
        final result = await _roomsService.lobby(session.sessionToken ?? '');
        _sendSocketResponse(
          session.socket,
          requestId: requestId,
          statusCode: result.statusCode,
          body: result.body,
        );
        return;
      case 'createRoom':
        final result = await _roomsService.createRoom(
          sessionToken: session.sessionToken ?? '',
          name: data['name']?.toString() ?? '',
          maxPlayers: (data['maxPlayers'] as num?)?.toInt() ?? 4,
        );
        if (result.statusCode == 201) {
          session.currentRoomId = result.body['room'] is Map<String, Object?>
              ? ((result.body['room']! as Map<String, Object?>)['id'] as num?)?.toInt()
              : session.currentRoomId;
        }
        _sendSocketResponse(
          session.socket,
          requestId: requestId,
          statusCode: result.statusCode,
          body: result.body,
        );
        return;
      case 'joinRoom':
        final result = await _roomsService.joinRoom(
          sessionToken: session.sessionToken ?? '',
          roomId: (data['roomId'] as num?)?.toInt() ?? -1,
        );
        if (result.statusCode == 200) {
          session.currentRoomId = (result.body['room'] as Map<String, Object?>?)?['id'] is num
              ? (((result.body['room'] as Map<String, Object?>)['id']) as num).toInt()
              : session.currentRoomId;
        }
        _sendSocketResponse(
          session.socket,
          requestId: requestId,
          statusCode: result.statusCode,
          body: result.body,
        );
        return;
      case 'fetchRoom':
        final result = await _roomsService.roomDetail(
          sessionToken: session.sessionToken ?? '',
          roomId: (data['roomId'] as num?)?.toInt() ?? -1,
        );
        _sendSocketResponse(
          session.socket,
          requestId: requestId,
          statusCode: result.statusCode,
          body: result.body,
        );
        return;
      case 'leaveRoom':
        final result = await _roomsService.leaveRoom(
          sessionToken: session.sessionToken ?? '',
          roomId: (data['roomId'] as num?)?.toInt() ?? -1,
        );
        if (result.statusCode == 200) {
          session.currentRoomId = null;
        }
        _sendSocketResponse(
          session.socket,
          requestId: requestId,
          statusCode: result.statusCode,
          body: result.body,
        );
        return;
    }

    _sendSocketResponse(
      session.socket,
      requestId: requestId,
      statusCode: 400,
      body: {'error': 'unknown_action'},
    );
  }

  Future<void> _applyAuthResult(_SocketSession session, AuthResult result) async {
    if (result.statusCode < 200 || result.statusCode >= 300) {
      return;
    }

    final token = result.body['sessionToken']?.toString();
    final userId = result.body['userId'] as int?;
    if (token == null || userId == null) {
      return;
    }

    session.sessionToken = token;
    session.userId = userId;
    await _roomsRepo.touchUser(userId);
  }

  void _sendSocketResponse(
    WebSocket socket, {
    required String? requestId,
    required int statusCode,
    required Map<String, Object?> body,
  }) {
    socket.add(
      jsonEncode({
        'type': 'response',
        'requestId': requestId,
        'statusCode': statusCode,
        'body': body,
      }),
    );
  }

  void _writeJsonResponse(
    HttpResponse response,
    int statusCode,
    Map<String, Object?> body,
  ) {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    unawaited(response.close());
  }
}

final class _SocketSession {
  final WebSocket socket;
  int? userId;
  int? currentRoomId;
  String? sessionToken;

  _SocketSession({required this.socket});
}
