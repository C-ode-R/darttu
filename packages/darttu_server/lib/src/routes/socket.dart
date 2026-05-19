import 'dart:convert';
import 'dart:io';

final class SocketSession {
  final WebSocket socket;
  int? userId;
  String? sessionToken;

  SocketSession({required this.socket, this.userId, this.sessionToken});
}

final class SocketRouteContext {
  final SocketSession session;
  final String? requestId;
  final Map<String, Object?> payload;

  const SocketRouteContext({
    required this.session,
    required this.requestId,
    required this.payload,
  });
}

final class SocketRouteResponse {
  final int statusCode;
  final Map<String, Object?> body;

  const SocketRouteResponse({required this.statusCode, required this.body});
}

typedef SocketActionHandler =
    Future<SocketRouteResponse?> Function(SocketRouteContext context);

typedef SocketMiddleware =
    Future<SocketRouteResponse?> Function(
      SocketRouteContext context,
      SocketActionHandler next,
    );

final class SocketActionDefinition {
  final String action;
  final SocketActionHandler handler;

  const SocketActionDefinition({required this.action, required this.handler});
}

SocketActionDefinition socketAction(
  String action,
  SocketActionHandler handler,
) {
  return SocketActionDefinition(action: action, handler: handler);
}

final class SocketRouter {
  final Map<String, SocketActionHandler> _handlers;
  final List<SocketMiddleware> _middlewares;

  SocketRouter(
    List<SocketActionDefinition> definitions, {
    List<SocketMiddleware> middlewares = const [],
  }) : _handlers = {
         for (final d in definitions) d.action: d.handler,
       },
       _middlewares = middlewares;

  Future<SocketRouteResponse?> route(
    String action,
    SocketRouteContext context,
  ) async {
    final handler = _handlers[action];
    if (handler == null) return null;

    SocketRouteResponse? result;
    Future<SocketRouteResponse?> runNext(SocketRouteContext ctx) async {
      result = await handler(ctx);
      return result;
    }

    SocketActionHandler chain = runNext;
    for (var i = _middlewares.length - 1; i >= 0; i--) {
      final middleware = _middlewares[i];
      final prev = chain;
      chain = (ctx) => middleware(ctx, prev);
    }

    return chain(context);
  }
}

Map<String, Object?>? decodeSocketMessage(String message) {
  try {
    final decoded = jsonDecode(message);
    return decoded is Map<String, Object?> ? decoded : null;
  } on FormatException {
    return null;
  }
}

void sendSocketResponse(
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
