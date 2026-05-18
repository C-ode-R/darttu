import 'dart:io';

import 'package:shelf/shelf.dart';

import 'http.dart';
import '../services/auth.dart';

final class AuthRoute {
  final AuthService _service;

  AuthRoute({required AuthService service}) : _service = service;

  Response health(Request request, Map<String, String> params) {
    stdout.writeln('[auth] health check');
    return jsonResponse(200, _service.health());
  }

  Future<Response> signup(Request request, Map<String, String> params) async {
    final payload = await decodeJsonBody(request);
    if (payload == null) {
      stdout.writeln('[auth] signup rejected: invalid_json');
      return jsonResponse(400, const {'error': 'invalid_json'});
    }

    final username = payload['username']?.toString() ?? '';
    final result = await _service.signup(
      username: username,
      password: payload['password']?.toString() ?? '',
    );
    stdout.writeln(
      '[auth] signup ${result.statusCode == 201 ? 'success' : 'failure'}: username="$username" status=${result.statusCode}',
    );
    return jsonResponse(result.statusCode, result.body);
  }

  Future<Response> login(Request request, Map<String, String> params) async {
    final payload = await decodeJsonBody(request);
    if (payload == null) {
      stdout.writeln('[auth] login rejected: invalid_json');
      return jsonResponse(400, const {'error': 'invalid_json'});
    }

    final username = payload['username']?.toString() ?? '';
    final result = await _service.login(
      username: username,
      password: payload['password']?.toString() ?? '',
    );
    stdout.writeln(
      '[auth] login ${result.statusCode == 200 ? 'success' : 'failure'}: username="$username" status=${result.statusCode}',
    );
    return jsonResponse(result.statusCode, result.body);
  }

  Future<Response> session(Request request, Map<String, String> params) async {
    final result = await _service.session(bearerToken(request));
    stdout.writeln(
      '[auth] session ${result.statusCode == 200 ? 'success' : 'failure'}: status=${result.statusCode}',
    );
    return jsonResponse(result.statusCode, result.body);
  }
}
