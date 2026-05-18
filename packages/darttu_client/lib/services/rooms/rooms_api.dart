import 'package:darttu_client/services/http/http_api.dart';

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

  const RoomMemberSummary({
    required this.userId,
    required this.username,
    required this.isHost,
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

final class RoomsApiService {
  final HttpApiService _httpApi;

  const RoomsApiService({HttpApiService httpApi = const HttpApiService()})
    : _httpApi = httpApi;

  Future<RoomsApiResult> fetchLobby({
    required Uri uri,
    required String sessionToken,
  }) async {
    final response = await _httpApi.getJsonWithHeaders(
      uri: uri,
      headers: {'authorization': 'Bearer $sessionToken'},
    );
    final roomsJson = response.body['rooms'];
    final usersJson = response.body['onlineUsers'];
    if (roomsJson is! List<Object?> || usersJson is! List<Object?>) {
      return _errorResult(response);
    }

    return RoomsApiResult(
      statusCode: response.statusCode,
      error: response.body['error']?.toString(),
      room: null,
      roomDetail: null,
      lobby: LobbySnapshot(
        rooms: roomsJson
            .whereType<Map<Object?, Object?>>()
            .map(_parseRoom)
            .toList(growable: false),
        onlineUsers: usersJson
            .whereType<Map<Object?, Object?>>()
            .map(_parseOnlineUser)
            .toList(growable: false),
      ),
    );
  }

  Future<RoomsApiResult> createRoom({
    required Uri uri,
    required String sessionToken,
    required String name,
    int maxPlayers = 4,
  }) async {
    final response = await _httpApi.postJsonWithHeaders(
      uri: uri,
      payload: {'name': name, 'maxPlayers': maxPlayers},
      headers: {'authorization': 'Bearer $sessionToken'},
    );
    final roomJson = response.body['room'];
    if (roomJson is! Map<Object?, Object?>) {
      return _errorResult(response);
    }

    return RoomsApiResult(
      statusCode: response.statusCode,
      error: response.body['error']?.toString(),
      room: _parseRoom(roomJson),
      roomDetail: null,
      lobby: null,
    );
  }

  Future<RoomsApiResult> joinRoom({
    required Uri uri,
    required String sessionToken,
  }) async {
    final response = await _httpApi.postJsonWithHeaders(
      uri: uri,
      payload: const {},
      headers: {'authorization': 'Bearer $sessionToken'},
    );
    final roomJson = response.body['room'];
    if (roomJson is! Map<Object?, Object?>) {
      return _errorResult(response);
    }

    return RoomsApiResult(
      statusCode: response.statusCode,
      error: response.body['error']?.toString(),
      room: null,
      roomDetail: _parseRoomDetail(roomJson),
      lobby: null,
    );
  }

  Future<RoomsApiResult> fetchRoom({
    required Uri uri,
    required String sessionToken,
  }) async {
    final response = await _httpApi.getJsonWithHeaders(
      uri: uri,
      headers: {'authorization': 'Bearer $sessionToken'},
    );
    final roomJson = response.body['room'];
    if (roomJson is! Map<Object?, Object?>) {
      return _errorResult(response);
    }

    return RoomsApiResult(
      statusCode: response.statusCode,
      error: response.body['error']?.toString(),
      room: null,
      roomDetail: _parseRoomDetail(roomJson),
      lobby: null,
    );
  }

  Future<RoomsApiResult> leaveRoom({
    required Uri uri,
    required String sessionToken,
  }) async {
    final response = await _httpApi.postJsonWithHeaders(
      uri: uri,
      payload: const {},
      headers: {'authorization': 'Bearer $sessionToken'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return RoomsApiResult(
        statusCode: response.statusCode,
        error: null,
        room: null,
        roomDetail: null,
        lobby: null,
      );
    }

    return _errorResult(response);
  }

  RoomsApiResult _errorResult(ApiResponse response) {
    return RoomsApiResult(
      statusCode: response.statusCode,
      error: response.body['error']?.toString() ?? 'invalid_server_response',
      room: null,
      roomDetail: null,
      lobby: null,
    );
  }

  RoomSummary _parseRoom(Map<Object?, Object?> json) {
    return RoomSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '이름 없는 방',
      currentPlayers: (json['currentPlayers'] as num?)?.toInt() ?? 0,
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 0,
    );
  }

  OnlineUserSummary _parseOnlineUser(Map<Object?, Object?> json) {
    return OnlineUserSummary(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? '알 수 없는 사용자',
      roomId: (json['roomId'] as num?)?.toInt(),
      roomName: json['roomName']?.toString(),
    );
  }

  RoomDetail _parseRoomDetail(Map<Object?, Object?> json) {
    final membersJson = json['members'];
    final members = membersJson is List<Object?>
        ? membersJson
              .whereType<Map<Object?, Object?>>()
              .map(
                (memberJson) => RoomMemberSummary(
                  userId: (memberJson['userId'] as num?)?.toInt() ?? 0,
                  username: memberJson['username']?.toString() ?? '알 수 없는 사용자',
                  isHost: memberJson['isHost'] == true,
                ),
              )
              .toList(growable: false)
        : const <RoomMemberSummary>[];

    return RoomDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '이름 없는 방',
      currentPlayers: (json['currentPlayers'] as num?)?.toInt() ?? 0,
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 0,
      members: members,
    );
  }
}
