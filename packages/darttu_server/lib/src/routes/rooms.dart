import 'dart:io';

import 'package:shelf/shelf.dart';

import 'http.dart';
import '../services/rooms.dart';

final class RoomsRoute {
  final RoomsService _service;

  RoomsRoute({required RoomsService service}) : _service = service;

  Future<Response> lobby(Request request, Map<String, String> params) async {
    final result = await _service.lobby(bearerToken(request));
    stdout.writeln(
      '[rooms] lobby ${result.statusCode == 200 ? 'success' : 'failure'}: status=${result.statusCode}',
    );
    return jsonResponse(result.statusCode, result.body);
  }

  Future<Response> heartbeat(Request request, Map<String, String> params) async {
    final result = await _service.heartbeat(bearerToken(request));
    stdout.writeln(
      '[rooms] heartbeat ${result.statusCode == 200 ? 'success' : 'failure'}: status=${result.statusCode}',
    );
    return jsonResponse(result.statusCode, result.body);
  }

  Future<Response> list(Request request, Map<String, String> params) async {
    final result = await _service.listRooms(bearerToken(request));
    stdout.writeln(
      '[rooms] list ${result.statusCode == 200 ? 'success' : 'failure'}: status=${result.statusCode}',
    );
    return jsonResponse(result.statusCode, result.body);
  }

  Future<Response> create(Request request, Map<String, String> params) async {
    final payload = await decodeJsonBody(request);
    if (payload == null) {
      stdout.writeln('[rooms] create rejected: invalid_json');
      return jsonResponse(400, const {'error': 'invalid_json'});
    }

    final roomName = payload['name']?.toString() ?? '';
    final result = await _service.createRoom(
      sessionToken: bearerToken(request),
      name: roomName,
      maxPlayers: (payload['maxPlayers'] as num?)?.toInt() ?? 4,
    );
    stdout.writeln(
      '[rooms] create ${result.statusCode == 201 ? 'success' : 'failure'}: name="$roomName" status=${result.statusCode}',
    );
    return jsonResponse(result.statusCode, result.body);
  }

  Future<Response> detail(Request request, Map<String, String> params) async {
    final roomId = int.tryParse(params['roomId'] ?? '');
    if (roomId == null) {
      return jsonResponse(400, const {'error': 'invalid_room_id'});
    }

    final result = await _service.roomDetail(
      sessionToken: bearerToken(request),
      roomId: roomId,
    );
    stdout.writeln(
      '[rooms] detail ${result.statusCode == 200 ? 'success' : 'failure'}: roomId=$roomId status=${result.statusCode}',
    );
    return jsonResponse(result.statusCode, result.body);
  }

  Future<Response> join(Request request, Map<String, String> params) async {
    final roomId = int.tryParse(params['roomId'] ?? '');
    if (roomId == null) {
      return jsonResponse(400, const {'error': 'invalid_room_id'});
    }

    final result = await _service.joinRoom(
      sessionToken: bearerToken(request),
      roomId: roomId,
    );
    stdout.writeln(
      '[rooms] join ${result.statusCode == 200 ? 'success' : 'failure'}: roomId=$roomId status=${result.statusCode}',
    );
    return jsonResponse(result.statusCode, result.body);
  }

  Future<Response> leave(Request request, Map<String, String> params) async {
    final roomId = int.tryParse(params['roomId'] ?? '');
    if (roomId == null) {
      return jsonResponse(400, const {'error': 'invalid_room_id'});
    }

    final result = await _service.leaveRoom(
      sessionToken: bearerToken(request),
      roomId: roomId,
    );
    stdout.writeln(
      '[rooms] leave ${result.statusCode == 200 ? 'success' : 'failure'}: roomId=$roomId status=${result.statusCode}',
    );
    return jsonResponse(result.statusCode, result.body);
  }
}
