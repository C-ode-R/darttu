import '../routes/socket.dart';
import '../services/session_validator.dart';

SocketMiddleware requireAuth(SessionValidator validator) {
  return (context, next) async {
    final token = context.session.sessionToken ?? '';
    final user = await validator.validate(token);
    if (user == null) {
      return const SocketRouteResponse(
        statusCode: 401,
        body: {'error': 'invalid_session'},
      );
    }

    return next(context);
  };
}
