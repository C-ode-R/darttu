import 'dart:async';

import 'package:darttu_client/app/app_controller.dart';
import 'package:darttu_client/app/app_state.dart';
import 'package:darttu_client/layout/layout.dart';
import 'package:darttu_client/services/auth/server_connect.dart';
import 'package:darttu_client/services/auth/session_store.dart';
import 'package:darttu_client/services/rooms/rooms_api.dart';
import 'package:darttu_client/ui/screen.dart';
import 'package:darttu_client/ui/terminal/keys.dart';

final _roomsApi = RoomsApiService();
const _serverConnect = ServerConnectService();
const _sessionStore = SessionStore();
const _defaultMaxPlayers = 4;
const _autoRefreshInterval = Duration(seconds: 5);

final class RoomListScreen implements AppScreen {
  Timer? _autoRefreshTimer;

  @override
  Widget build(AppState state) {
    final username = state.get<String>('auth.username') ?? '알 수 없는 사용자';
    final rooms = state.getOrDefault<List<RoomSummary>>(
      'roomList.rooms',
      const <RoomSummary>[],
    );
    final onlineUsers = state.getOrDefault<List<OnlineUserSummary>>(
      'roomList.onlineUsers',
      const <OnlineUserSummary>[],
    );
    final selectedIndex = state.getOrDefault<int>('roomList.selectedIndex', 0);
    final message = state.get<String>('roomList.message');
    final isLoading = state.getOrDefault<bool>('roomList.loading', false);
    final isCreating = state.getOrDefault<bool>('roomList.isCreating', false);
    final createName = state.getOrDefault<String>('roomList.createName', '');
    final frame = state.getOrDefault<int>('ui.frame', 0);
    final displaySelectedIndex = rooms.isEmpty
        ? 0
        : selectedIndex.clamp(0, rooms.length - 1);

    return Column(
      children: [
        SizedBox(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: StatusLine(
            left: '사용자: $username',
            right: isLoading ? '동기화 중' : '방 ${rooms.length}개',
          ),
        ),
        Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            gap: 2,
            children: [
              Card(
                title: '접속 중인 유저',
                width: const PercentWidth(0.33),
                child: onlineUsers.isEmpty
                    ? Text(
                        '현재 접속 중인 유저가 없습니다.',
                        foregroundColor: TerminalColor.brightBlack,
                      )
                    : Menu(
                        items: onlineUsers
                            .map(
                              (user) => user.roomName == null
                                  ? user.username
                                  : '${user.username} - ${user.roomName}',
                            )
                            .toList(growable: false),
                        selectedIndex: -1,
                        foregroundColor: TerminalColor.white,
                      ),
              ),
              Card(
                title: '방 목록',
                width: const FlexWidth(1),
                child: Column(
                  children: [
                    Text(
                      isCreating
                          ? '방 이름 입력 후 Enter로 생성, Esc로 취소'
                          : '상하 방향키로 선택, Enter로 입장, C로 방 만들기, R로 새로고침',
                      foregroundColor: TerminalColor.brightBlack,
                    ),
                    SizedBox(height: 1),
                    if (isCreating) ...[
                      InputLine(
                        label: '방 이름',
                        value: createName,
                        focused: true,
                      ),
                      SizedBox(height: 1),
                      Text(
                        '최대 인원은 $_defaultMaxPlayers명으로 생성됩니다.',
                        foregroundColor: TerminalColor.brightBlack,
                      ),
                    ] else if (isLoading) ...[
                      Row(
                        gap: 1,
                        children: [
                          SmallSpinner(
                            frame: frame,
                            foregroundColor: TerminalColor.brightCyan,
                          ),
                          Text('로비 정보를 불러오는 중입니다...'),
                        ],
                      ),
                    ] else if (rooms.isEmpty) ...[
                      Text(
                        '현재 생성된 방이 없습니다.',
                        foregroundColor: TerminalColor.brightBlack,
                      ),
                    ] else ...[
                      Menu(
                        items: rooms
                            .map(
                              (room) =>
                                  '${room.name} (${room.currentPlayers}/${room.maxPlayers})',
                            )
                            .toList(growable: false),
                        selectedIndex: displaySelectedIndex,
                        selectedForegroundColor: TerminalColor.black,
                        selectedBackgroundColor: TerminalColor.brightCyan,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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

  @override
  void handleInput(String input, AppState state, AppController controller) {
    final rooms = state.getOrDefault<List<RoomSummary>>(
      'roomList.rooms',
      const <RoomSummary>[],
    );
    final isLoading = state.getOrDefault<bool>('roomList.loading', false);
    final isCreating = state.getOrDefault<bool>('roomList.isCreating', false);

    if (isCreating) {
      _handleCreateInput(input, state, controller);
      return;
    }

    if (input == 'r' || input == 'R') {
      unawaited(_loadLobby(state, controller));
      return;
    }

    if (input == 'c' || input == 'C') {
      controller.setValue<bool>('roomList.isCreating', true);
      controller.setValue<String>('roomList.createName', '');
      controller.setValue<String>('roomList.message', '새 방 이름을 입력해주세요.');
      return;
    }

    if (isLoading || rooms.isEmpty) {
      return;
    }

    final selectedIndex = state.getOrDefault<int>('roomList.selectedIndex', 0);

    if (input == Keys.arrowUp) {
      controller.setValue<int>(
        'roomList.selectedIndex',
        (selectedIndex - 1 + rooms.length) % rooms.length,
      );
      return;
    }

    if (input == Keys.arrowDown) {
      controller.setValue<int>(
        'roomList.selectedIndex',
        (selectedIndex + 1) % rooms.length,
      );
      return;
    }

    if (Keys.isEnter(input)) {
      final room = rooms[selectedIndex.clamp(0, rooms.length - 1)];
      unawaited(_joinRoom(state, controller, room));
    }
  }

  @override
  void onEnter(AppState state, AppController controller) {
    controller.setValue<bool>('roomList.isCreating', false);
    controller.setValue<String>('roomList.createName', '');
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (controller.state.screenState != ScreenState.roomList) {
        return;
      }
      if (controller.state.getOrDefault<bool>('roomList.isCreating', false)) {
        return;
      }
      if (controller.state.getOrDefault<bool>('roomList.loading', false)) {
        return;
      }

      unawaited(
        _loadLobby(
          controller.state,
          controller,
          successMessage: controller.state.get<String>('roomList.message'),
        ),
      );
    });
    unawaited(_loadLobby(state, controller));
  }

  @override
  void onExit(AppState state, AppController controller) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  Future<void> _loadLobby(
    AppState state,
    AppController controller, {
    String? successMessage,
    int? preferredRoomId,
  }) async {
    final sessionToken = state.get<String>('auth.sessionToken') ?? '';
    if (sessionToken.isEmpty) {
      controller.setScreenState(ScreenState.auth);
      return;
    }

    controller.setValue<bool>('roomList.loading', true);
    final host = state.getOrDefault<String>('server.host', officialServerHost);
    final port = state.get<int>('server.port');
    final result = await _roomsApi.fetchLobby(
      uri: _serverConnect.lobbyUri(host: host, port: port),
      sessionToken: sessionToken,
    );
    controller.setValue<bool>('roomList.loading', false);

    if (result.statusCode == 200 && result.lobby != null) {
      controller.setValue<List<RoomSummary>>(
        'roomList.rooms',
        result.lobby!.rooms,
      );
      controller.setValue<List<OnlineUserSummary>>(
        'roomList.onlineUsers',
        result.lobby!.onlineUsers,
      );
      final currentSelectedIndex = state.getOrDefault<int>(
        'roomList.selectedIndex',
        0,
      );
      final preferredIndex = preferredRoomId == null
          ? -1
          : result.lobby!.rooms.indexWhere(
              (room) => room.id == preferredRoomId,
            );
      final nextSelectedIndex = result.lobby!.rooms.isEmpty
          ? 0
          : preferredIndex >= 0
          ? preferredIndex
          : currentSelectedIndex.clamp(0, result.lobby!.rooms.length - 1);
      controller.setValue<int>('roomList.selectedIndex', nextSelectedIndex);
      controller.setValue<String>(
        'roomList.message',
        successMessage ?? '로비 정보를 불러왔습니다.',
      );
      return;
    }

    if (result.statusCode == 401) {
      await _expireSession(controller);
      return;
    }

    controller.setValue<List<RoomSummary>>(
      'roomList.rooms',
      const <RoomSummary>[],
    );
    controller.setValue<List<OnlineUserSummary>>(
      'roomList.onlineUsers',
      const <OnlineUserSummary>[],
    );
    controller.setValue<String>(
      'roomList.message',
      _messageForError(result.error ?? 'unknown_error'),
    );
  }

  void _handleCreateInput(
    String input,
    AppState state,
    AppController controller,
  ) {
    if (input == Keys.escape) {
      controller.setValue<bool>('roomList.isCreating', false);
      controller.setValue<String>('roomList.createName', '');
      controller.setValue<String>('roomList.message', '방 생성이 취소되었습니다.');
      return;
    }

    if (Keys.isBackspace(input)) {
      final current = state.getOrDefault<String>('roomList.createName', '');
      if (current.isEmpty) {
        return;
      }
      controller.setValue<String>(
        'roomList.createName',
        current.substring(0, current.length - 1),
      );
      return;
    }

    if (Keys.isPrintable(input)) {
      final current = state.getOrDefault<String>('roomList.createName', '');
      controller.setValue<String>('roomList.createName', '$current$input');
      return;
    }

    if (Keys.isEnter(input)) {
      unawaited(_createRoom(state, controller));
    }
  }

  Future<void> _createRoom(AppState state, AppController controller) async {
    final roomName = state.getOrDefault<String>('roomList.createName', '');
    if (roomName.trim().isEmpty) {
      controller.setValue<String>('roomList.message', '방 이름을 입력해주세요.');
      return;
    }

    controller.setValue<bool>('roomList.loading', true);
    final host = state.getOrDefault<String>('server.host', officialServerHost);
    final port = state.get<int>('server.port');
    final result = await _roomsApi.createRoom(
      uri: _serverConnect.roomsUri(host: host, port: port),
      sessionToken: state.get<String>('auth.sessionToken') ?? '',
      name: roomName,
      maxPlayers: _defaultMaxPlayers,
    );
    controller.setValue<bool>('roomList.loading', false);

    if (result.statusCode == 201 && result.room != null) {
      controller.setValue<bool>('roomList.isCreating', false);
      controller.setValue<String>('roomList.createName', '');
      controller.setValue<int>('room.currentRoomId', result.room!.id);
      controller.setValue<String>('room.currentRoomName', result.room!.name);
      controller.setValue<String>(
        'room.message',
        '"${result.room!.name}" 방을 만들었습니다.',
      );
      controller.setScreenState(ScreenState.room);
      return;
    }

    if (result.statusCode == 401) {
      await _expireSession(controller);
      return;
    }

    controller.setValue<String>(
      'roomList.message',
      _messageForError(result.error ?? 'unknown_error'),
    );
  }

  Future<void> _joinRoom(
    AppState state,
    AppController controller,
    RoomSummary room,
  ) async {
    controller.setValue<bool>('roomList.loading', true);
    final host = state.getOrDefault<String>('server.host', officialServerHost);
    final port = state.get<int>('server.port');
    final result = await _roomsApi.joinRoom(
      uri: _serverConnect.joinRoomUri(roomId: room.id, host: host, port: port),
      sessionToken: state.get<String>('auth.sessionToken') ?? '',
    );
    controller.setValue<bool>('roomList.loading', false);

    if (result.statusCode == 200 && result.roomDetail != null) {
      controller.setValue<int>('room.currentRoomId', result.roomDetail!.id);
      controller.setValue<String>(
        'room.currentRoomName',
        result.roomDetail!.name,
      );
      controller.setValue<List<RoomMemberSummary>>(
        'room.members',
        result.roomDetail!.members,
      );
      controller.setValue<int>(
        'room.currentPlayers',
        result.roomDetail!.currentPlayers,
      );
      controller.setValue<int>(
        'room.maxPlayers',
        result.roomDetail!.maxPlayers,
      );
      controller.setValue<String>(
        'room.message',
        '"${result.roomDetail!.name}" 방에 입장했습니다.',
      );
      controller.setScreenState(ScreenState.room);
      return;
    }

    if (result.statusCode == 401) {
      await _expireSession(controller);
      return;
    }

    controller.setValue<String>(
      'roomList.message',
      _messageForError(result.error ?? 'unknown_error'),
    );
  }

  Future<void> _expireSession(AppController controller) async {
    controller.setValue<int>('auth.userId', null);
    controller.setValue<String>('auth.username', null);
    controller.setValue<String>('auth.sessionToken', null);
    await _sessionStore.clear();
    controller.setValue<String>('auth.message', '세션이 만료되어 다시 로그인해야 합니다.');
    controller.setScreenState(ScreenState.auth);
  }

  String _messageForError(String error) {
    switch (error) {
      case 'session_required':
      case 'invalid_session':
        return '세션이 만료되었습니다.';
      case 'invalid_room_name':
        return '방 이름을 확인해주세요.';
      case 'invalid_room_capacity':
        return '방 인원 설정이 올바르지 않습니다.';
      case 'room_name_already_exists':
        return '이미 같은 이름의 방이 있습니다.';
      case 'room_not_found':
        return '방을 찾을 수 없습니다.';
      case 'room_full':
        return '방 인원이 가득 찼습니다.';
      case 'invalid_json':
        return '요청 형식이 올바르지 않습니다.';
      case 'server_unreachable':
        return '서버에 연결할 수 없습니다.';
      case 'invalid_server_response':
        return '서버 응답을 해석할 수 없습니다.';
    }

    return error;
  }
}
