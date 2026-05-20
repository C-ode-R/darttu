final class RoomSummary {
  final int id;
  final String name;
  final int currentPlayers;
  final int maxPlayers;

  const RoomSummary({
    required this.id,
    required this.name,
    required this.currentPlayers,
    required this.maxPlayers,
  });
}

final class OnlineUserSummary {
  final int userId;
  final String username;
  final int? roomId;
  final String? roomName;

  const OnlineUserSummary({
    required this.userId,
    required this.username,
    required this.roomId,
    required this.roomName,
  });
}

final class RoomMemberSummary {
  final int userId;
  final String username;
  final bool isHost;
  final bool isReady;

  const RoomMemberSummary({
    required this.userId,
    required this.username,
    required this.isHost,
    required this.isReady,
  });
}

final class RoomDetail {
  final int id;
  final String name;
  final int currentPlayers;
  final int maxPlayers;
  final List<RoomMemberSummary> members;

  const RoomDetail({
    required this.id,
    required this.name,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.members,
  });
}

final class LobbySnapshot {
  final List<RoomSummary> rooms;
  final List<OnlineUserSummary> onlineUsers;

  const LobbySnapshot({required this.rooms, required this.onlineUsers});
}

final class RoomsApiResult {
  final int statusCode;
  final String? error;
  final RoomSummary? room;
  final RoomDetail? roomDetail;
  final LobbySnapshot? lobby;

  const RoomsApiResult({
    required this.statusCode,
    required this.error,
    required this.room,
    required this.roomDetail,
    required this.lobby,
  });
}
