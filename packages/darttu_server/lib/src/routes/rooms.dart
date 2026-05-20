import '../services/rooms.dart';
import 'socket.dart';

final class RoomsSocketRoutes {
  final RoomsService _rooms;

  RoomsSocketRoutes({required RoomsService rooms}) : _rooms = rooms;

  List<SocketActionDefinition> get definitions {
    return [
      socketAction('ping', _ping),
      socketAction('lobby', _lobby),
      socketAction('createRoom', _create),
      socketAction('joinRoom', _join),
      socketAction('fetchRoom', _detail),
      socketAction('leaveRoom', _leave),
      socketAction('toggleReady', _toggleReady),
      socketAction('startGame', _startGame),
    ];
  }

  Future<SocketRouteResponse?> _ping(SocketRouteContext context) async {
    return const SocketRouteResponse(statusCode: 200, body: {'ok': true});
  }

  Future<SocketRouteResponse?> _lobby(SocketRouteContext _) async {
    final result = await _rooms.lobby();
    return SocketRouteResponse(
      statusCode: result.statusCode,
      body: result.body,
    );
  }

  Future<SocketRouteResponse?> _create(SocketRouteContext context) async {
    final result = await _rooms.create(
      name: context.payload['name']?.toString() ?? '',
      maxPlayers: (context.payload['maxPlayers'] as num?)?.toInt() ?? 4,
      ownerUserId: context.session.userId!,
    );
    return SocketRouteResponse(
      statusCode: result.statusCode,
      body: result.body,
    );
  }

  Future<SocketRouteResponse?> _join(SocketRouteContext context) async {
    final result = await _rooms.join(
      roomId: (context.payload['roomId'] as num?)?.toInt() ?? -1,
      userId: context.session.userId!,
    );
    return SocketRouteResponse(
      statusCode: result.statusCode,
      body: result.body,
    );
  }

  Future<SocketRouteResponse?> _detail(SocketRouteContext context) async {
    final result = await _rooms.detail(
      roomId: (context.payload['roomId'] as num?)?.toInt() ?? -1,
    );
    return SocketRouteResponse(
      statusCode: result.statusCode,
      body: result.body,
    );
  }

  Future<SocketRouteResponse?> _leave(SocketRouteContext context) async {
    final result = await _rooms.leave(
      roomId: (context.payload['roomId'] as num?)?.toInt() ?? -1,
      userId: context.session.userId!,
    );
    return SocketRouteResponse(
      statusCode: result.statusCode,
      body: result.body,
    );
  }

  Future<SocketRouteResponse?> _toggleReady(SocketRouteContext context) async {
    final result = await _rooms.toggleReady(
      roomId: (context.payload['roomId'] as num?)?.toInt() ?? -1,
      userId: context.session.userId!,
    );
    return SocketRouteResponse(
      statusCode: result.statusCode,
      body: result.body,
    );
  }

  Future<SocketRouteResponse?> _startGame(SocketRouteContext context) async {
    final result = await _rooms.startGame(
      roomId: (context.payload['roomId'] as num?)?.toInt() ?? -1,
      hostUserId: context.session.userId!,
    );
    return SocketRouteResponse(
      statusCode: result.statusCode,
      body: result.body,
    );
  }
}
