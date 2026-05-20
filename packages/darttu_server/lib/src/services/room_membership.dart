import '../repositories/rooms.dart';

final class RoomMembershipService {
  final RoomRepo _rooms;
  final RoomMemberRepo _members;
  final PresenceRepo _presence;
  final int _presenceTimeoutSeconds;
  final Future<void> Function() _onRoomChanged;

  RoomMembershipService({
    required RoomRepo rooms,
    required RoomMemberRepo members,
    required PresenceRepo presence,
    int presenceTimeoutSeconds = 60,
    Future<void> Function()? onRoomChanged,
  }) : _rooms = rooms,
       _members = members,
       _presence = presence,
       _presenceTimeoutSeconds = presenceTimeoutSeconds,
       _onRoomChanged = onRoomChanged ?? (() async {});

  Future<void> cleanupStaleUsers() async {
    final staleIds = await _presence.staleUserIds(
      staleAfterSeconds: _presenceTimeoutSeconds,
    );

    for (final userId in staleIds) {
      await disconnectUser(userId);
    }
  }

  Future<void> disconnectUser(int userId) async {
    await _rooms.transaction(() async {
      final affectedRoomIds = await _presence.roomIdsForUser(userId);
      await _members.removeUserFromAllRooms(userId);
      await _presence.removeOnlineUser(userId);
      await _normalizeRooms(affectedRoomIds);
    });
    await _onRoomChanged();
  }

  Future<RoomSummary?> createRoom({
    required String name,
    required int currentPlayers,
    required int maxPlayers,
    required int ownerUserId,
  }) async {
    try {
      late final int roomId;

      await _rooms.transaction(() async {
        final previousRoomId = await _members.findUserRoomId(ownerUserId);
        roomId = await _rooms.create(
          name: name,
          currentPlayers: currentPlayers,
          maxPlayers: maxPlayers,
        );

        await _members.removeUserFromAllRooms(ownerUserId);
        await _members.addUserToRoom(roomId: roomId, userId: ownerUserId);

        if (previousRoomId != null) {
          await _normalizeRoom(previousRoomId);
        }
        await _normalizeRoom(roomId);
      });

      await _onRoomChanged();
      return _rooms.summary(roomId);
    } on Object {
      return null;
    }
  }

  Future<RoomDetail?> joinRoom({
    required int roomId,
    required int userId,
  }) async {
    await _rooms.transaction(() async {
      final previousRoomId = await _members.findUserRoomId(userId);

      await _members.removeUserFromAllRooms(userId);
      await _members.addUserToRoom(roomId: roomId, userId: userId);

      if (previousRoomId != null) {
        await _normalizeRoom(previousRoomId);
      }
      await _normalizeRoom(roomId);
    });

    await _onRoomChanged();
    return _rooms.detail(roomId);
  }

  Future<RoomDetail?> leaveRoom({
    required int roomId,
    required int userId,
  }) async {
    await _rooms.transaction(() async {
      await _members.removeUserFromRoom(roomId: roomId, userId: userId);
      await _normalizeRoom(roomId);
    });

    await _onRoomChanged();
    return _rooms.detail(roomId);
  }

  Future<void> toggleReady({
    required int roomId,
    required int userId,
  }) async {
    await _members.toggleReady(roomId: roomId, userId: userId);
    await _onRoomChanged();
  }

  Future<void> _normalizeRooms(Set<int> roomIds) async {
    for (final roomId in roomIds) {
      await _normalizeRoom(roomId);
    }
  }

  Future<void> _normalizeRoom(int roomId) async {
    final count = await _rooms.memberCount(roomId);
    if (count <= 0) {
      await _rooms.delete(roomId);
      return;
    }

    await _rooms.updatePlayerCount(id: roomId, count: count);
  }
}
