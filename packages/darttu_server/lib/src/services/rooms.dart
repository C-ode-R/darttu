import '../repositories/rooms.dart';
import 'room_membership.dart';

final class RoomsResult {
  final int statusCode;
  final Map<String, Object?> body;

  const RoomsResult({required this.statusCode, required this.body});
}

final class RoomsService {
  final RoomRepo _rooms;
  final RoomMembershipService _membership;
  final Future<void> Function() _onRoomChanged;

  RoomsService({
    required RoomRepo rooms,
    required RoomMembershipService membership,
    Future<void> Function()? onRoomChanged,
  }) : _rooms = rooms,
       _membership = membership,
       _onRoomChanged = onRoomChanged ?? (() async {});

  Future<RoomsResult> lobby() async {
    final snapshot = await _rooms.lobbySnapshot();

    return RoomsResult(
      statusCode: 200,
      body: {
        'rooms': snapshot.rooms.map(RoomsPresenter.toJson).toList(growable: false),
        'onlineUsers': snapshot.onlineUsers
            .map(RoomsPresenter.onlineUserToJson)
            .toList(growable: false),
      },
    );
  }

  Future<RoomsResult> heartbeat() async {
    return const RoomsResult(statusCode: 200, body: {'ok': true});
  }

  Future<RoomsResult> list() async {
    final rooms = await _rooms.list();

    return RoomsResult(
      statusCode: 200,
      body: {'rooms': rooms.map(RoomsPresenter.toJson).toList(growable: false)},
    );
  }

  Future<RoomsResult> create({
    required String name,
    required int maxPlayers,
    required int ownerUserId,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return const RoomsResult(
        statusCode: 400,
        body: {'error': 'invalid_room_name'},
      );
    }

    if (maxPlayers < 2 || maxPlayers > 8) {
      return const RoomsResult(
        statusCode: 400,
        body: {'error': 'invalid_room_capacity'},
      );
    }

    final room = await _membership.createRoom(
      name: normalizedName,
      currentPlayers: 1,
      maxPlayers: maxPlayers,
      ownerUserId: ownerUserId,
    );
    if (room == null) {
      return const RoomsResult(
        statusCode: 409,
        body: {'error': 'room_name_already_exists'},
      );
    }

    _onRoomChanged();
    return RoomsResult(statusCode: 201, body: {'room': RoomsPresenter.toJson(room)});
  }

  Future<RoomsResult> detail({required int roomId}) async {
    final room = await _rooms.detail(roomId);
    if (room == null) {
      return const RoomsResult(
        statusCode: 404,
        body: {'error': 'room_not_found'},
      );
    }

    return RoomsResult(statusCode: 200, body: {'room': RoomsPresenter.toDetailJson(room)});
  }

  Future<RoomsResult> join({
    required int roomId,
    required int userId,
  }) async {
    final existingRoom = await _rooms.detail(roomId);
    if (existingRoom == null) {
      return const RoomsResult(
        statusCode: 404,
        body: {'error': 'room_not_found'},
      );
    }
    if (existingRoom.currentPlayers >= existingRoom.maxPlayers &&
        !existingRoom.members.any((m) => m.userId == userId)) {
      return const RoomsResult(statusCode: 409, body: {'error': 'room_full'});
    }

    final room = await _membership.joinRoom(roomId: roomId, userId: userId);
    if (room == null) {
      return const RoomsResult(
        statusCode: 404,
        body: {'error': 'room_not_found'},
      );
    }

    _onRoomChanged();
    return RoomsResult(statusCode: 200, body: {'room': RoomsPresenter.toDetailJson(room)});
  }

  Future<RoomsResult> leave({
    required int roomId,
    required int userId,
  }) async {
    await _membership.leaveRoom(roomId: roomId, userId: userId);
    _onRoomChanged();
    return const RoomsResult(statusCode: 200, body: {'ok': true});
  }
}

final class RoomsPresenter {
  static Map<String, Object?> toJson(RoomSummary room) {
    return {
      'id': room.id,
      'name': room.name,
      'currentPlayers': room.currentPlayers,
      'maxPlayers': room.maxPlayers,
    };
  }

  static Map<String, Object?> toDetailJson(RoomDetail room) {
    return {
      'id': room.id,
      'name': room.name,
      'currentPlayers': room.currentPlayers,
      'maxPlayers': room.maxPlayers,
      'members': room.members
          .map(
            (member) => <String, Object?>{
              'userId': member.userId,
              'username': member.username,
              'isHost': member.isHost,
            },
          )
          .toList(growable: false),
    };
  }

  static Map<String, Object?> onlineUserToJson(OnlineUserSummary user) {
    return <String, Object?>{
      'userId': user.userId,
      'username': user.username,
      'roomId': user.roomId,
      'roomName': user.roomName,
    };
  }
}
