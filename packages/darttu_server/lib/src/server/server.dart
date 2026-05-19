import 'dart:async';
import 'dart:io';

import '../routes/http.dart';
import '../routes/socket.dart';
import 'socket_connection_lifecycle.dart';
import 'socket_session_factory.dart';

final class Server {
  final HttpRouter _httpRouter;
  final SocketRouter _socketRouter;
  final SocketSessionFactory _socketSessionFactory;
  final SocketConnectionLifecycle _socketConnectionLifecycle;
  final Future<void> Function() _onClose;
  final Set<SocketSession> _sessions = <SocketSession>{};
  HttpServer? _httpServer;

  Server({
    required HttpRouter httpRouter,
    required SocketRouter socketRouter,
    required SocketSessionFactory socketSessionFactory,
    required SocketConnectionLifecycle socketConnectionLifecycle,
    required Future<void> Function() onClose,
  }) : _httpRouter = httpRouter,
       _socketRouter = socketRouter,
       _socketSessionFactory = socketSessionFactory,
       _socketConnectionLifecycle = socketConnectionLifecycle,
       _onClose = onClose;

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
    await _onClose();
  }

  Future<void> _listen(HttpServer server) async {
    await for (final request in server) {
      final startedAt = DateTime.now();
      stdout.writeln(
        '[${startedAt.toIso8601String()}] -> ${request.method} ${request.uri.path}',
      );

      try {
        if (request.uri.path == '/ws' &&
            WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          final session = await _socketSessionFactory.create(request, socket);
          _sessions.add(session);
          unawaited(_handleSocket(session));
          continue;
        }

        final handled = await _httpRouter.handle(request);
        if (handled) {
          unawaited(request.response.close());
          continue;
        }

        writeJsonResponse(request.response, 404, {'error': 'not_found'});
        unawaited(request.response.close());
      } on Object catch (error, stackTrace) {
        stdout.writeln(
          '[${DateTime.now().toIso8601String()}] !! ${request.method} ${request.uri.path} failed: $error',
        );
        stderr.writeln(stackTrace);
        try {
          writeJsonResponse(request.response, 500, {
            'error': 'internal_server_error',
          });
          await request.response.close();
        } on Object {
          await request.response.close();
        }
      }
    }
  }

  Future<void> _handleSocket(SocketSession session) async {
    try {
      await for (final message in session.socket) {
        if (message is! String) {
          continue;
        }

        await _handleSocketMessage(session, message);
      }
    } finally {
      _sessions.remove(session);
      await _socketConnectionLifecycle.onDisconnected(session);
    }
  }

  Future<void> _handleSocketMessage(
    SocketSession session,
    String message,
  ) async {
    final decoded = decodeSocketMessage(message);
    if (decoded == null) {
      sendSocketResponse(
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
    final data = payload is Map<String, Object?>
        ? payload
        : <String, Object?>{};

    final response = await _socketRouter.route(
      action,
      SocketRouteContext(session: session, requestId: requestId, payload: data),
    );

    if (response == null) {
      sendSocketResponse(
        session.socket,
        requestId: requestId,
        statusCode: 400,
        body: {'error': 'unknown_action'},
      );
      return;
    }

    sendSocketResponse(
      session.socket,
      requestId: requestId,
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}
