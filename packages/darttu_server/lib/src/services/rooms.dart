import '../repositories/auth.dart';
import '../repositories/rooms.dart';

final class RoomsResult {
  final int statusCode;
  final Map<String, Object?> body;

  const RoomsResult({required this.statusCode, required this.body});
}

final class RoomsService {
  final AuthRepo _authRepo;
  final RoomsRepo _roomsRepo;

  RoomsService({required AuthRepo authRepo, required RoomsRepo roomsRepo})
    : _authRepo = authRepo,
      _roomsRepo = roomsRepo;

  Future<RoomsResult> lobby(String sessionToken) async {
    final sessionState = await _validatedSession(sessionToken);
    if (sessionState == null) {
      return const RoomsResult(
        statusCode: 401,
        body: {'error': 'invalid_session'},
      );
    }

    await _roomsRepo.cleanupStaleUsers();
    await _roomsRepo.touchUser(sessionState.user.id);
    final snapshot = await _roomsRepo.getLobbySnapshot();

    return RoomsResult(
      statusCode: 200,
      body: {
        'rooms': snapshot.rooms.map(_roomJson).toList(growable: false),
        'onlineUsers': snapshot.onlineUsers
            .map(
              (user) => <String, Object?>{
                'userId': user.userId,
                'username': user.username,
                'roomId': user.roomId,
                'roomName': user.roomName,
              },
            )
            .toList(growable: false),
      },
    );
  }

  Future<RoomsResult> listRooms(String sessionToken) async {
    final sessionState = await _validatedSession(sessionToken);
    if (sessionState == null) {
      return const RoomsResult(
        statusCode: 401,
        body: {'error': 'invalid_session'},
      );
    }

    await _roomsRepo.cleanupStaleUsers();
    await _roomsRepo.touchUser(sessionState.user.id);
    final rooms = await _roomsRepo.listRooms();

    return RoomsResult(
      statusCode: 200,
      body: {'rooms': rooms.map(_roomJson).toList(growable: false)},
    );
  }

  Future<RoomsResult> createRoom({
    required String sessionToken,
    required String name,
    int maxPlayers = 4,
  }) async {
    final sessionState = await _validatedSession(sessionToken);
    if (sessionState == null) {
      return const RoomsResult(
        statusCode: 401,
        body: {'error': 'invalid_session'},
      );
    }

    await _roomsRepo.cleanupStaleUsers();
    await _roomsRepo.touchUser(sessionState.user.id);

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

    final room = await _roomsRepo.createRoom(
      name: normalizedName,
      currentPlayers: 1,
      maxPlayers: maxPlayers,
      ownerUserId: sessionState.user.id,
    );
    if (room == null) {
      return const RoomsResult(
        statusCode: 409,
        body: {'error': 'room_name_already_exists'},
      );
    }

    return RoomsResult(statusCode: 201, body: {'room': _roomJson(room)});
  }

  Future<RoomsResult> roomDetail({
    required String sessionToken,
    required int roomId,
  }) async {
    final sessionState = await _validatedSession(sessionToken);
    if (sessionState == null) {
      return const RoomsResult(
        statusCode: 401,
        body: {'error': 'invalid_session'},
      );
    }

    await _roomsRepo.cleanupStaleUsers();
    await _roomsRepo.touchUser(sessionState.user.id);
    final room = await _roomsRepo.getRoom(roomId);
    if (room == null) {
      return const RoomsResult(
        statusCode: 404,
        body: {'error': 'room_not_found'},
      );
    }

    return RoomsResult(statusCode: 200, body: {'room': _roomDetailJson(room)});
  }

  Future<RoomsResult> joinRoom({
    required String sessionToken,
    required int roomId,
  }) async {
    final sessionState = await _validatedSession(sessionToken);
    if (sessionState == null) {
      return const RoomsResult(
        statusCode: 401,
        body: {'error': 'invalid_session'},
      );
    }

    await _roomsRepo.cleanupStaleUsers();
    await _roomsRepo.touchUser(sessionState.user.id);
    final existingRoom = await _roomsRepo.getRoom(roomId);
    if (existingRoom == null) {
      return const RoomsResult(
        statusCode: 404,
        body: {'error': 'room_not_found'},
      );
    }
    if (existingRoom.currentPlayers >= existingRoom.maxPlayers &&
        !existingRoom.members.any(
          (member) => member.userId == sessionState.user.id,
        )) {
      return const RoomsResult(statusCode: 409, body: {'error': 'room_full'});
    }

    final room = await _roomsRepo.joinRoom(
      roomId: roomId,
      userId: sessionState.user.id,
    );
    if (room == null) {
      return const RoomsResult(
        statusCode: 404,
        body: {'error': 'room_not_found'},
      );
    }

    return RoomsResult(statusCode: 200, body: {'room': _roomDetailJson(room)});
  }

  Future<RoomsResult> leaveRoom({
    required String sessionToken,
    required int roomId,
  }) async {
    final sessionState = await _validatedSession(sessionToken);
    if (sessionState == null) {
      return const RoomsResult(
        statusCode: 401,
        body: {'error': 'invalid_session'},
      );
    }

    await _roomsRepo.cleanupStaleUsers();
    await _roomsRepo.touchUser(sessionState.user.id);
    await _roomsRepo.leaveRoom(roomId: roomId, userId: sessionState.user.id);

    return const RoomsResult(statusCode: 200, body: {'ok': true});
  }

  Future<_ValidatedSession?> _validatedSession(String sessionToken) async {
    if (sessionToken.isEmpty) {
      return null;
    }

    final session = await _authRepo.findSessionByToken(sessionToken);
    if (session == null) {
      return null;
    }

    final user = await _authRepo.findById(session.userId);
    if (user == null) {
      return null;
    }

    return _ValidatedSession(user: user);
  }

  Map<String, Object?> _roomJson(RoomSummary room) {
    return {
      'id': room.id,
      'name': room.name,
      'currentPlayers': room.currentPlayers,
      'maxPlayers': room.maxPlayers,
    };
  }

  Map<String, Object?> _roomDetailJson(RoomDetail room) {
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
}

final class _ValidatedSession {
  final AuthUser user;

  const _ValidatedSession({required this.user});
}
