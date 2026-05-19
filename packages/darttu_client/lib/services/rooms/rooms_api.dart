import '../http/http_api.dart';
import '../network/socket_client.dart';
import 'models.dart';
import 'rooms_client.dart';

final class RoomsApi implements RoomsClient {
  final AppSocketClient _socket;

  RoomsApi({required AppSocketClient socket}) : _socket = socket;

  @override
  Future<RoomsApiResult> fetchLobby({
    required Uri uri,
    required String sessionToken,
  }) async {
    await _socket.connect(uri: uri, sessionToken: sessionToken);
    final response = await _socket.call(action: 'lobby');
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

  @override
  Future<RoomsApiResult> createRoom({
    required Uri uri,
    required String sessionToken,
    required String name,
    int maxPlayers = 4,
  }) async {
    await _socket.connect(uri: uri, sessionToken: sessionToken);
    final response = await _socket.call(
      action: 'createRoom',
      payload: {'name': name, 'maxPlayers': maxPlayers},
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

  @override
  Future<RoomsApiResult> joinRoom({
    required Uri uri,
    required String sessionToken,
    required int roomId,
  }) async {
    await _socket.connect(uri: uri, sessionToken: sessionToken);
    final response = await _socket.call(
      action: 'joinRoom',
      payload: {'roomId': roomId},
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

  @override
  Future<RoomsApiResult> fetchRoom({
    required Uri uri,
    required String sessionToken,
    required int roomId,
  }) async {
    await _socket.connect(uri: uri, sessionToken: sessionToken);
    final response = await _socket.call(
      action: 'fetchRoom',
      payload: {'roomId': roomId},
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

  @override
  Future<RoomsApiResult> leaveRoom({
    required Uri uri,
    required String sessionToken,
    required int roomId,
  }) async {
    await _socket.connect(uri: uri, sessionToken: sessionToken);
    final response = await _socket.call(
      action: 'leaveRoom',
      payload: {'roomId': roomId},
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
                (m) => RoomMemberSummary(
                  userId: (m['userId'] as num?)?.toInt() ?? 0,
                  username: m['username']?.toString() ?? '알 수 없는 사용자',
                  isHost: m['isHost'] == true,
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
