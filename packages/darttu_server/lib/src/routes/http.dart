import 'dart:convert';
import 'dart:io';

enum HttpRouteMethod { get, post, put, patch, delete }

typedef HttpRouteHandler = Future<void> Function(HttpRequest request);

final class HttpRouteDefinition {
  final HttpRouteMethod method;
  final String path;
  final HttpRouteHandler handler;

  const HttpRouteDefinition({
    required this.method,
    required this.path,
    required this.handler,
  });
}

HttpRouteDefinition httpRoute(
  HttpRouteMethod method,
  String path,
  HttpRouteHandler handler,
) {
  return HttpRouteDefinition(method: method, path: path, handler: handler);
}

final class HttpRouter {
  final Map<String, HttpRouteHandler> _routes;

  HttpRouter(List<HttpRouteDefinition> routes)
    : _routes = {
        for (final route in routes)
          _routeKey(route.method, route.path): route.handler,
      };

  Future<bool> handle(HttpRequest request) async {
    final handler =
        _routes[_routeKey(_methodFor(request.method), request.uri.path)];
    if (handler == null) {
      return false;
    }

    await handler(request);
    return true;
  }

  static String _routeKey(HttpRouteMethod method, String path) {
    return '${method.name.toUpperCase()} $path';
  }

  static HttpRouteMethod _methodFor(String method) {
    return switch (method.toUpperCase()) {
      'GET' => HttpRouteMethod.get,
      'POST' => HttpRouteMethod.post,
      'PUT' => HttpRouteMethod.put,
      'PATCH' => HttpRouteMethod.patch,
      'DELETE' => HttpRouteMethod.delete,
      _ => HttpRouteMethod.get,
    };
  }
}

Future<Map<String, Object?>?> decodeJsonRequest(HttpRequest request) async {
  try {
    final body = await utf8.decoder.bind(request).join();
    if (body.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(body);
    return decoded is Map<String, Object?> ? decoded : null;
  } on FormatException {
    return null;
  }
}

String bearerToken(HttpRequest request) {
  final authorization = request.headers.value(HttpHeaders.authorizationHeader);
  if (authorization == null) {
    return '';
  }

  const prefix = 'Bearer ';
  if (!authorization.startsWith(prefix)) {
    return '';
  }

  return authorization.substring(prefix.length).trim();
}

void writeJsonResponse(
  HttpResponse response,
  int statusCode,
  Map<String, Object?> body,
) {
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
}
