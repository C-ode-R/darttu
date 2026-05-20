import 'dart:async';
import 'dart:io';

import 'package:darttu_client/app/auth_session_coordinator.dart';
import 'package:darttu_client/app/app_controller.dart';
import 'package:darttu_client/app/app_state.dart';
import 'package:darttu_client/layout/layout.dart';
import 'package:darttu_client/services/auth/server_connect.dart';
import 'package:darttu_client/services/network/socket_client.dart';
import 'package:darttu_client/services/rooms/rooms_client.dart';
import 'package:darttu_client/services/rooms/models.dart';
import 'package:darttu_client/ui/error_messages.dart';
import 'package:darttu_client/ui/screen.dart';
import 'package:darttu_client/ui/terminal/keys.dart';

final class RoomScreen implements AppScreen {
  final RoomsClient _roomsClient;
  final ServerConnectService _serverConnect;
  final AuthSessionCoordinator _authSessionCoordinator;
  final AppSocketClient _socket;

  RoomScreen({
    required RoomsClient roomsClient,
    required ServerConnectService serverConnect,
    required AuthSessionCoordinator authSessionCoordinator,
    required AppSocketClient socket,
  }) : _roomsClient = roomsClient,
       _serverConnect = serverConnect,
       _authSessionCoordinator = authSessionCoordinator,
       _socket = socket;

  @override
  Widget build(AppState state) {
    final roomName = state.get<String>('room.currentRoomName') ?? '방';
    final members = state.getOrDefault<List<RoomMemberSummary>>(
      'room.members',
      const <RoomMemberSummary>[],
    );
    final message = state.get<String>('room.message');
    final isLoading = state.getOrDefault<bool>('room.loading', false);
    final frame = state.getOrDefault<int>('ui.frame', 0);
    final currentPlayers = state.getOrDefault<int>('room.currentPlayers', 0);
    final maxPlayers = state.getOrDefault<int>('room.maxPlayers', 0);
    final myUserId = state.get<int>('auth.userId');
    final isHost = members.isNotEmpty &&
        myUserId != null &&
        members.first.userId == myUserId;
    final allReady = members.isNotEmpty && members.every((m) => m.isReady);

    return Column(
      children: [
        SizedBox(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: StatusLine(
            left: '방: $roomName',
            right: '$currentPlayers/$maxPlayers',
          ),
        ),
        Spacer(),
        Center(
          child: Card(
            title: '방 내부',
            width: const PercentWidth(0.7),
            child: Column(
              children: [
                Text(
                  _buildHelpText(isHost, allReady),
                  foregroundColor: TerminalColor.brightBlack,
                ),
                SizedBox(height: 1),
                if (isLoading) ...[
                  Row(
                    gap: 1,
                    children: [
                      SmallSpinner(
                        frame: frame,
                        foregroundColor: TerminalColor.brightCyan,
                      ),
                      Text('방 정보를 불러오는 중입니다...'),
                    ],
                  ),
                ] else if (members.isEmpty) ...[
                  Text(
                    '현재 방에 유저가 없습니다.',
                    foregroundColor: TerminalColor.brightBlack,
                  ),
                ] else ...[
                  Menu(
                    items: members
                        .map(
                          (member) => _memberLabel(member, myUserId),
                        )
                        .toList(),
                    selectedIndex: -1,
                    foregroundColor: TerminalColor.white,
                  ),
                ],
              ],
            ),
          ),
          height: const AutoHeight(),
        ),
        SizedBox(height: 1),
        Center(
          child: Text(
            message ?? '',
            foregroundColor: TerminalColor.brightYellow,
          ),
          height: const AutoHeight(),
        ),
        Spacer(),
      ],
    );
  }

  String _buildHelpText(bool isHost, bool allReady) {
    final parts = <String>[
      'R로 새로고침',
      if (!isHost) 'Space로 준비/해제',
      if (isHost && allReady) 'Enter로 게임 시작',
      'B/Esc로 방 나가기',
      'L로 로비',
    ];
    return parts.join(', ');
  }

  String _memberLabel(RoomMemberSummary member, int? myUserId) {
    final isMe = member.userId == myUserId;
    final readyTag = member.isReady ? '[준비]' : '[대기]';
    final hostTag = member.isHost ? '(방장)' : '';
    final meTag = isMe ? '(나)' : '';
    return '${member.username} $readyTag $hostTag$meTag';
  }

  @override
  void handleInput(String input, AppState state, AppController controller) {
    stderr.writeln('[room] input received: "${input}" (code: ${input.codeUnitAt(0)})');
    if (input == 'r' || input == 'R') {
      unawaited(_loadRoom(state, controller));
      return;
    }

    if (input == 'l' || input == 'L') {
      controller.setScreenState(ScreenState.roomList);
      return;
    }

    final members = state.getOrDefault<List<RoomMemberSummary>>(
      'room.members',
      const <RoomMemberSummary>[],
    );
    final myUserId = state.get<int>('auth.userId');
    final isHost = members.isNotEmpty &&
        myUserId != null &&
        members.first.userId == myUserId;

    stderr.writeln('[room] isHost=$isHost, myUserId=$myUserId, members=${members.length}');

    if (input == ' ' && !isHost) {
      stderr.writeln('[room] toggleReady triggered');
      unawaited(_toggleReady(state, controller));
      return;
    }

    if (Keys.isEnter(input) && isHost) {
      unawaited(_startGame(state, controller));
      return;
    }

    if (input == 'b' || input == 'B' || input == Keys.escape) {
      unawaited(_leaveRoom(state, controller));
    }
  }

  @override
  void onEnter(AppState state, AppController controller) {
    _handleBroadcast(state, controller);
    unawaited(_loadRoom(state, controller));
  }

  @override
  void onExit(AppState state, AppController controller) {
    _socket.onBroadcast = null;
  }

  void _handleBroadcast(AppState state, AppController controller) {
    _socket.onBroadcast = (message) {
      final action = message['action']?.toString();
      if (action != 'roomUpdate') return;
      if (state.screenState != ScreenState.room) return;

      final body = message['body'];
      if (body is! Map<String, Object?>) return;

      final roomJson = body['room'];
      if (roomJson is! Map<Object?, Object?>) return;

      final room = _parseRoomDetail(roomJson);
      _applyRoomDetail(room, controller);
    };
  }

  Future<void> _loadRoom(AppState state, AppController controller) async {
    final roomId = state.get<int>('room.currentRoomId');
    final sessionToken = state.get<String>('auth.sessionToken') ?? '';
    if (roomId == null || sessionToken.isEmpty) {
      controller.setScreenState(ScreenState.roomList);
      return;
    }

    controller.setValue<bool>('room.loading', true);
    final host = state.getOrDefault<String>('server.host', officialServerHost);
    final port = state.get<int>('server.port');
    final result = await _roomsClient.fetchRoom(
      uri: _serverConnect.socketUri(host: host, port: port),
      sessionToken: sessionToken,
      roomId: roomId,
    );
    controller.setValue<bool>('room.loading', false);

    if (result.statusCode == 200 && result.roomDetail != null) {
      _applyRoomDetail(result.roomDetail!, controller);
      controller.setValue<String>('room.message', '방 정보를 불러왔습니다.');
      return;
    }

    if (result.statusCode == 401) {
      await _expireSession(controller);
      return;
    }

    if (result.statusCode == 404) {
      controller.setValue<String>('room.message', '방이 더 이상 존재하지 않습니다.');
      controller.setScreenState(ScreenState.roomList);
      return;
    }

    controller.setValue<String>(
      'room.message',
      _messageForError(result.error ?? 'unknown_error'),
    );
  }

  Future<void> _toggleReady(AppState state, AppController controller) async {
    final roomId = state.get<int>('room.currentRoomId');
    final sessionToken = state.get<String>('auth.sessionToken') ?? '';
    if (roomId == null || sessionToken.isEmpty) return;

    final host = state.getOrDefault<String>('server.host', officialServerHost);
    final port = state.get<int>('server.port');
    final result = await _roomsClient.toggleReady(
      uri: _serverConnect.socketUri(host: host, port: port),
      sessionToken: sessionToken,
      roomId: roomId,
    );

    if (result.statusCode == 200 && result.roomDetail != null) {
      _applyRoomDetail(result.roomDetail!, controller);
      return;
    }

    if (result.statusCode == 401) {
      await _expireSession(controller);
    }
  }

  Future<void> _startGame(AppState state, AppController controller) async {
    final roomId = state.get<int>('room.currentRoomId');
    final sessionToken = state.get<String>('auth.sessionToken') ?? '';
    if (roomId == null || sessionToken.isEmpty) return;

    final host = state.getOrDefault<String>('server.host', officialServerHost);
    final port = state.get<int>('server.port');
    final result = await _roomsClient.startGame(
      uri: _serverConnect.socketUri(host: host, port: port),
      sessionToken: sessionToken,
      roomId: roomId,
    );

    if (result.statusCode == 200) {
      controller.setValue<String>('room.message', '게임이 시작되었습니다!');
      return;
    }

    if (result.statusCode == 400) {
      controller.setValue<String>('room.message', '모든 플레이어가 준비해야 합니다.');
      return;
    }

    if (result.statusCode == 401) {
      await _expireSession(controller);
    }
  }

  Future<void> _leaveRoom(AppState state, AppController controller) async {
    final roomId = state.get<int>('room.currentRoomId');
    final sessionToken = state.get<String>('auth.sessionToken') ?? '';
    if (roomId == null || sessionToken.isEmpty) {
      controller.setScreenState(ScreenState.roomList);
      return;
    }

    final result = await _roomsClient.leaveRoom(
      uri: _serverConnect.socketUri(
        host: state.getOrDefault<String>('server.host', officialServerHost),
        port: state.get<int>('server.port'),
      ),
      sessionToken: sessionToken,
      roomId: roomId,
    );

    if (result.statusCode == 200) {
      controller.setValue<int>('room.currentRoomId', null);
      controller.setValue<String>('room.currentRoomName', null);
      controller.setValue<List<RoomMemberSummary>>('room.members', null);
      controller.setValue<int>('room.currentPlayers', null);
      controller.setValue<int>('room.maxPlayers', null);
      controller.setValue<String>('roomList.message', '방에서 나왔습니다.');
      controller.setScreenState(ScreenState.roomList);
      return;
    }

    if (result.statusCode == 401) {
      await _expireSession(controller);
      return;
    }

    controller.setValue<String>(
      'room.message',
      _messageForError(result.error ?? 'unknown_error'),
    );
  }

  RoomMemberSummary _parseMember(Map<Object?, Object?> json) {
    return RoomMemberSummary(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? '알 수 없는 사용자',
      isHost: json['isHost'] == true,
      isReady: json['isReady'] == true,
    );
  }

  RoomDetail _parseRoomDetail(Map<Object?, Object?> json) {
    final membersJson = json['members'];
    final members = membersJson is List<Object?>
        ? membersJson
              .whereType<Map<Object?, Object?>>()
              .map(_parseMember)
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

  void _applyRoomDetail(RoomDetail room, AppController controller) {
    controller.setValue<int>('room.currentRoomId', room.id);
    controller.setValue<String>('room.currentRoomName', room.name);
    controller.setValue<List<RoomMemberSummary>>('room.members', room.members);
    controller.setValue<int>('room.currentPlayers', room.currentPlayers);
    controller.setValue<int>('room.maxPlayers', room.maxPlayers);
  }

  Future<void> _expireSession(AppController controller) async {
    await _authSessionCoordinator.expireSession(controller);
  }

  String _messageForError(String error) {
    return resolveErrorMessage(
      error,
      catalogs: const [
        roomErrorMessages,
        sessionErrorMessages,
        commonErrorMessages,
      ],
    );
  }
}
