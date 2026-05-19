import 'dart:io';

import '../routes/http.dart';
import '../routes/socket.dart';
import '../services/session_validator.dart';

abstract interface class SocketSessionFactory {
  Future<SocketSession> create(HttpRequest request, WebSocket socket);
}

final class AuthSocketSessionFactory implements SocketSessionFactory {
  final SessionValidator _validator;

  AuthSocketSessionFactory({required SessionValidator validator})
    : _validator = validator;

  @override
  Future<SocketSession> create(HttpRequest request, WebSocket socket) async {
    final token = bearerToken(request);
    final user = await _validator.validate(token);
    if (user == null) {
      return SocketSession(socket: socket);
    }

    return SocketSession(
      socket: socket,
      userId: user.id,
      sessionToken: token,
    );
  }
}
