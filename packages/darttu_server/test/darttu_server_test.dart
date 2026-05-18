import 'dart:convert';
import 'dart:io';

import 'package:darttu_server/darttu_server.dart';
import 'package:test/test.dart';

Future<Map<String, Object?>> _jsonResponse(HttpClientResponse response) async {
  final body = await utf8.decoder.bind(response).join();
  return jsonDecode(body) as Map<String, Object?>;
}

void main() {
  test('health, signup, and login routes work', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'darttu_server_test_',
    );
    final databasePath = '${tempDir.path}/server.sqlite';
    final server = Server(databasePath: databasePath);
    final httpServer = await server.serve(host: '127.0.0.1', port: 0);

    addTearDown(() async {
      await httpServer.close(force: true);
      await server.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final healthClient = HttpClient();
    addTearDown(() => healthClient.close(force: true));
    final healthRequest = await healthClient.getUrl(
      Uri.parse('http://127.0.0.1:${httpServer.port}/health'),
    );
    final healthResponse = await healthRequest.close();
    expect(healthResponse.statusCode, HttpStatus.ok);
    expect(await _jsonResponse(healthResponse), {'status': 'ok'});

    final signupRequest = await healthClient.postUrl(
      Uri.parse('http://127.0.0.1:${httpServer.port}/auth/signup'),
    );
    signupRequest.headers.contentType = ContentType.json;
    signupRequest.write(
      jsonEncode({'username': 'alice', 'password': 'pw1234'}),
    );
    final signupResponse = await signupRequest.close();
    expect(signupResponse.statusCode, HttpStatus.created);
    final signupBody = await _jsonResponse(signupResponse);
    expect(signupBody['userId'], 1);
    expect(signupBody['username'], 'alice');
    final signupSessionToken = signupBody['sessionToken'] as String;
    expect(signupSessionToken.isNotEmpty, true);

    final duplicateSignupRequest = await healthClient.postUrl(
      Uri.parse('http://127.0.0.1:${httpServer.port}/auth/signup'),
    );
    duplicateSignupRequest.headers.contentType = ContentType.json;
    duplicateSignupRequest.write(
      jsonEncode({'username': 'alice', 'password': 'pw1234'}),
    );
    final duplicateSignupResponse = await duplicateSignupRequest.close();
    expect(duplicateSignupResponse.statusCode, HttpStatus.conflict);

    final loginRequest = await healthClient.postUrl(
      Uri.parse('http://127.0.0.1:${httpServer.port}/auth/login'),
    );
    loginRequest.headers.contentType = ContentType.json;
    loginRequest.write(jsonEncode({'username': 'alice', 'password': 'pw1234'}));
    final loginResponse = await loginRequest.close();
    expect(loginResponse.statusCode, HttpStatus.ok);
    final loginBody = await _jsonResponse(loginResponse);
    expect(loginBody['userId'], 1);
    expect(loginBody['username'], 'alice');
    final loginSessionToken = loginBody['sessionToken'] as String;
    expect(loginSessionToken.isNotEmpty, true);

    final sessionRequest = await healthClient.getUrl(
      Uri.parse('http://127.0.0.1:${httpServer.port}/auth/session'),
    );
    sessionRequest.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer $loginSessionToken',
    );
    final sessionResponse = await sessionRequest.close();
    expect(sessionResponse.statusCode, HttpStatus.ok);
    final sessionBody = await _jsonResponse(sessionResponse);
    expect(sessionBody['userId'], 1);
    expect(sessionBody['username'], 'alice');
    expect(sessionBody['sessionToken'], loginSessionToken);

    final roomsRequest = await healthClient.getUrl(
      Uri.parse('http://127.0.0.1:${httpServer.port}/rooms'),
    );
    roomsRequest.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer $loginSessionToken',
    );
    final roomsResponse = await roomsRequest.close();
    expect(roomsResponse.statusCode, HttpStatus.ok);
    final roomsBody = await _jsonResponse(roomsResponse);
    final rooms = roomsBody['rooms'] as List<Object?>;
    expect(rooms.length, greaterThanOrEqualTo(3));
    expect(rooms.first, {
      'id': 1,
      'name': '초보자 환영방',
      'currentPlayers': 1,
      'maxPlayers': 4,
    });

    final createRoomRequest = await healthClient.postUrl(
      Uri.parse('http://127.0.0.1:${httpServer.port}/rooms'),
    );
    createRoomRequest.headers.contentType = ContentType.json;
    createRoomRequest.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer $loginSessionToken',
    );
    createRoomRequest.write(jsonEncode({'name': '새 방', 'maxPlayers': 4}));
    final createRoomResponse = await createRoomRequest.close();
    expect(createRoomResponse.statusCode, HttpStatus.created);
    final createRoomBody = await _jsonResponse(createRoomResponse);
    expect(createRoomBody['room'], {
      'id': 4,
      'name': '새 방',
      'currentPlayers': 1,
      'maxPlayers': 4,
    });

    final duplicateRoomRequest = await healthClient.postUrl(
      Uri.parse('http://127.0.0.1:${httpServer.port}/rooms'),
    );
    duplicateRoomRequest.headers.contentType = ContentType.json;
    duplicateRoomRequest.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer $loginSessionToken',
    );
    duplicateRoomRequest.write(jsonEncode({'name': '새 방'}));
    final duplicateRoomResponse = await duplicateRoomRequest.close();
    expect(duplicateRoomResponse.statusCode, HttpStatus.conflict);

    final unauthorizedRoomsRequest = await healthClient.getUrl(
      Uri.parse('http://127.0.0.1:${httpServer.port}/rooms'),
    );
    final unauthorizedRoomsResponse = await unauthorizedRoomsRequest.close();
    expect(unauthorizedRoomsResponse.statusCode, HttpStatus.unauthorized);

    final invalidSessionRequest = await healthClient.getUrl(
      Uri.parse('http://127.0.0.1:${httpServer.port}/auth/session'),
    );
    invalidSessionRequest.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer invalid-token',
    );
    final invalidSessionResponse = await invalidSessionRequest.close();
    expect(invalidSessionResponse.statusCode, HttpStatus.unauthorized);

    final invalidLoginRequest = await healthClient.postUrl(
      Uri.parse('http://127.0.0.1:${httpServer.port}/auth/login'),
    );
    invalidLoginRequest.headers.contentType = ContentType.json;
    invalidLoginRequest.write(
      jsonEncode({'username': 'alice', 'password': 'wrong'}),
    );
    final invalidLoginResponse = await invalidLoginRequest.close();
    expect(invalidLoginResponse.statusCode, HttpStatus.unauthorized);
  });
}
