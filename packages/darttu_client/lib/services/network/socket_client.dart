import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../http/http_api.dart';
import 'socket_connection.dart';

final class AppSocketClient implements SocketConnection {
  WebSocket? _socket;
  Uri? _uri;
  String? _sessionToken;
  StreamSubscription<Object?>? _subscription;
  int _requestCounter = 0;
  final Map<String, Completer<ApiResponse>> _pending =
      <String, Completer<ApiResponse>>{};

  void Function(Map<String, Object?>)? onBroadcast;

  bool get isConnected => _socket != null;

  Future<void> connect({required Uri uri, String? sessionToken}) async {
    if (_socket != null && _uri == uri && _sessionToken == sessionToken) {
      return;
    }

    await disconnect();

    try {
      final socket = await WebSocket.connect(
        uri.toString(),
        headers: sessionToken == null || sessionToken.isEmpty
            ? null
            : <String, Object>{'authorization': 'Bearer $sessionToken'},
      );
      _socket = socket;
      _uri = uri;
      _sessionToken = sessionToken;
      _subscription = socket.listen(
        _handleMessage,
        onDone: _handleClosed,
        onError: (_) => _handleClosed(),
        cancelOnError: true,
      );
    } on SocketException {
      throw const SocketException('server_unreachable');
    } on WebSocketException {
      throw const SocketException('server_unreachable');
    } on HttpException {
      throw const SocketException('server_unreachable');
    }
  }

  @override
  Future<void> disconnect() async {
    final socket = _socket;
    _socket = null;
    _uri = null;
    _sessionToken = null;

    await _subscription?.cancel();
    _subscription = null;

    if (socket != null) {
      await socket.close();
    }

    _failPending(
      const ApiResponse(statusCode: 503, body: {'error': 'server_unreachable'}),
    );
  }

  Future<ApiResponse> call({
    required String action,
    Map<String, Object?> payload = const <String, Object?>{},
  }) async {
    final socket = _socket;
    if (socket == null) {
      return const ApiResponse(
        statusCode: 503,
        body: {'error': 'server_unreachable'},
      );
    }

    final requestId = (++_requestCounter).toString();
    final completer = Completer<ApiResponse>();
    _pending[requestId] = completer;

    try {
      socket.add(
        jsonEncode({
          'requestId': requestId,
          'action': action,
          'payload': payload,
        }),
      );
    } on WebSocketException {
      _pending.remove(requestId);
      return const ApiResponse(
        statusCode: 503,
        body: {'error': 'server_unreachable'},
      );
    }

    return completer.future;
  }

  void _handleMessage(Object? message) {
    if (message is! String) {
      return;
    }

    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map<String, Object?>) {
        return;
      }

      final type = decoded['type']?.toString();
      if (type == 'broadcast') {
        stderr.writeln('[socket] broadcast received: ${decoded['action']}');
        onBroadcast?.call(decoded);
        return;
      }

      final requestId = decoded['requestId']?.toString();
      if (requestId == null) {
        return;
      }

      final completer = _pending.remove(requestId);
      if (completer == null) {
        return;
      }

      final statusCode = (decoded['statusCode'] as num?)?.toInt() ?? 500;
      final body = decoded['body'];
      if (body is! Map<String, Object?>) {
        completer.complete(
          const ApiResponse(
            statusCode: 500,
            body: {'error': 'invalid_server_response'},
          ),
        );
        return;
      }

      completer.complete(ApiResponse(statusCode: statusCode, body: body));
    } on FormatException {
      // Ignore malformed socket messages.
    }
  }

  void _handleClosed() {
    _socket = null;
    _uri = null;
    _sessionToken = null;
    _failPending(
      const ApiResponse(statusCode: 503, body: {'error': 'server_unreachable'}),
    );
  }

  void _failPending(ApiResponse response) {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.complete(response);
      }
    }
    _pending.clear();
  }
}
