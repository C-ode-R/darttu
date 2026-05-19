import 'dart:async';
import 'dart:io';

import '../services/auth.dart';
import 'http.dart';

final class AuthHttpRoutes {
  final AuthService _service;

  AuthHttpRoutes({required AuthService service}) : _service = service;

  List<HttpRouteDefinition> get definitions {
    return [
      httpRoute(HttpRouteMethod.get, '/health', _health),
      httpRoute(HttpRouteMethod.post, '/auth/signup', _signup),
      httpRoute(HttpRouteMethod.post, '/auth/login', _login),
      httpRoute(HttpRouteMethod.get, '/auth/session', _session),
    ];
  }

  Future<void> _health(HttpRequest request) async {
    writeJsonResponse(request.response, 200, {'status': 'ok'});
  }

  Future<void> _signup(HttpRequest request) async {
    final payload = await decodeJsonRequest(request);
    if (payload == null) {
      writeJsonResponse(request.response, 400, {'error': 'invalid_json'});
      return;
    }

    final result = await _service.signup(
      username: payload['username']?.toString() ?? '',
      password: payload['password']?.toString() ?? '',
    );
    writeJsonResponse(request.response, result.statusCode, result.body);
  }

  Future<void> _login(HttpRequest request) async {
    final payload = await decodeJsonRequest(request);
    if (payload == null) {
      writeJsonResponse(request.response, 400, {'error': 'invalid_json'});
      return;
    }

    final result = await _service.login(
      username: payload['username']?.toString() ?? '',
      password: payload['password']?.toString() ?? '',
    );
    writeJsonResponse(request.response, result.statusCode, result.body);
  }

  Future<void> _session(HttpRequest request) async {
    final result = await _service.session(bearerToken(request));
    writeJsonResponse(request.response, result.statusCode, result.body);
  }
}
