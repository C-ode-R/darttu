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

final class RoomScreen implements AppScreen {
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
                  'R로 새로고침, B 또는 Esc로 방 나가기',
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
                          (member) => member.isHost
                              ? '${member.username} (방장)'
                              : member.username,
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

  @override
  void handleInput(String input, AppState state, AppController controller) {
    if (input == 'r' || input == 'R') {
      unawaited(_loadRoom(state, controller));
      return;
    }

    if (input == 'b' || input == 'B' || input == Keys.escape) {
      unawaited(_leaveRoom(state, controller));
    }
  }

  @override
  void onEnter(AppState state, AppController controller) {
    unawaited(_loadRoom(state, controller));
  }

  @override
  void onExit(AppState state, AppController controller) {}

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
    final result = await _roomsApi.fetchRoom(
      uri: _serverConnect.roomUri(roomId: roomId, host: host, port: port),
      sessionToken: sessionToken,
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

  Future<void> _leaveRoom(AppState state, AppController controller) async {
    final roomId = state.get<int>('room.currentRoomId');
    final sessionToken = state.get<String>('auth.sessionToken') ?? '';
    if (roomId == null || sessionToken.isEmpty) {
      controller.setScreenState(ScreenState.roomList);
      return;
    }

    final result = await _roomsApi.leaveRoom(
      uri: _serverConnect.leaveRoomUri(
        roomId: roomId,
        host: state.getOrDefault<String>('server.host', officialServerHost),
        port: state.get<int>('server.port'),
      ),
      sessionToken: sessionToken,
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

  void _applyRoomDetail(RoomDetail room, AppController controller) {
    controller.setValue<int>('room.currentRoomId', room.id);
    controller.setValue<String>('room.currentRoomName', room.name);
    controller.setValue<List<RoomMemberSummary>>('room.members', room.members);
    controller.setValue<int>('room.currentPlayers', room.currentPlayers);
    controller.setValue<int>('room.maxPlayers', room.maxPlayers);
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
      case 'room_not_found':
        return '방을 찾을 수 없습니다.';
      case 'invalid_session':
        return '세션이 만료되었습니다.';
      case 'server_unreachable':
        return '서버에 연결할 수 없습니다.';
      case 'invalid_server_response':
        return '서버 응답을 해석할 수 없습니다.';
    }

    return error;
  }
}
