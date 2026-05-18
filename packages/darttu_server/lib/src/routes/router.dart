import 'dart:async';

import 'package:shelf/shelf.dart';

import 'auth.dart';
import 'rooms.dart';

typedef HttpRouteHandler =
    FutureOr<Response> Function(Request request, Map<String, String> params);

enum RouteMethod { get, post, put, patch, delete }

final class RoutePattern {
  final String raw;
  final List<String> _segments;
  final List<bool> _paramFlags;

  RoutePattern(this.raw)
    : _segments = _normalize(raw),
      _paramFlags = _normalize(
        raw,
      ).map((segment) => segment.startsWith(':')).toList(growable: false);

  bool get isStatic => !_paramFlags.any((value) => value);

  String get normalizedPath => '/${_segments.join('/')}';

  Map<String, String>? match(String path) {
    final pathSegments = _normalize(path);
    if (pathSegments.length != _segments.length) {
      return null;
    }

    final params = <String, String>{};
    for (var index = 0; index < _segments.length; index += 1) {
      final patternSegment = _segments[index];
      final pathSegment = pathSegments[index];

      if (_paramFlags[index]) {
        params[patternSegment.substring(1)] = pathSegment;
        continue;
      }

      if (patternSegment != pathSegment) {
        return null;
      }
    }

    return params;
  }

  static List<String> _normalize(String path) {
    if (path.isEmpty || path == '/') {
      return const <String>[];
    }

    return path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
  }
}

final class HttpRouteDefinition {
  final RouteMethod method;
  final RoutePattern pattern;
  final HttpRouteHandler handler;

  const HttpRouteDefinition({
    required this.method,
    required this.pattern,
    required this.handler,
  });
}

HttpRouteDefinition http(
  RouteMethod method,
  String path,
  HttpRouteHandler handler,
) {
  return HttpRouteDefinition(
    method: method,
    pattern: RoutePattern(path),
    handler: handler,
  );
}

final class Router {
  final Map<String, HttpRouteDefinition> _staticHttpRoutes;
  final List<HttpRouteDefinition> _dynamicHttpRoutes;

  Router({required AuthRoute authRoute, required RoomsRoute roomsRoute})
    : _staticHttpRoutes = _buildStaticHttpRoutes([
        http(RouteMethod.get, '/health', authRoute.health),
        http(RouteMethod.get, '/auth/session', authRoute.session),
        http(RouteMethod.post, '/auth/signup', authRoute.signup),
        http(RouteMethod.post, '/auth/login', authRoute.login),
        http(RouteMethod.get, '/lobby', roomsRoute.lobby),
        http(RouteMethod.get, '/rooms', roomsRoute.list),
        http(RouteMethod.post, '/rooms', roomsRoute.create),
      ]),
      _dynamicHttpRoutes = _buildDynamicHttpRoutes([
        http(RouteMethod.get, '/rooms/:roomId', roomsRoute.detail),
        http(RouteMethod.post, '/rooms/:roomId/join', roomsRoute.join),
        http(RouteMethod.post, '/rooms/:roomId/leave', roomsRoute.leave),
      ]);

  Handler get handler {
    return (Request request) async {
      final path = '/${request.url.path}';
      final method = _httpMethodFromRequest(request);

      final staticHttpRoute = _staticHttpRoutes[_httpRouteKey(method, path)];
      if (staticHttpRoute != null) {
        return staticHttpRoute.handler(request, const {});
      }

      for (final route in _dynamicHttpRoutes) {
        if (route.method != method) {
          continue;
        }
        final params = route.pattern.match(path);
        if (params != null) {
          return route.handler(request, params);
        }
      }

      return Response.notFound('Not Found');
    };
  }

  static Map<String, HttpRouteDefinition> _buildStaticHttpRoutes(
    List<HttpRouteDefinition> routes,
  ) {
    return {
      for (final route in routes.where((route) => route.pattern.isStatic))
        _httpRouteKey(route.method, route.pattern.normalizedPath): route,
    };
  }

  static List<HttpRouteDefinition> _buildDynamicHttpRoutes(
    List<HttpRouteDefinition> routes,
  ) {
    return routes
        .where((route) => !route.pattern.isStatic)
        .toList(growable: false);
  }

  static String _httpRouteKey(RouteMethod method, String path) {
    return '${method.name.toUpperCase()} $path';
  }

  static RouteMethod _httpMethodFromRequest(Request request) {
    return switch (request.method.toUpperCase()) {
      'GET' => RouteMethod.get,
      'POST' => RouteMethod.post,
      'PUT' => RouteMethod.put,
      'PATCH' => RouteMethod.patch,
      'DELETE' => RouteMethod.delete,
      _ => RouteMethod.get,
    };
  }
}
