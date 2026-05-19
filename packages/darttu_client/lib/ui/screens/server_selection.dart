import 'dart:async';

import 'package:darttu_client/app/app_controller.dart';
import 'package:darttu_client/app/app_state.dart';
import 'package:darttu_client/layout/layout.dart';
import 'package:darttu_client/services/auth/auth_client.dart';
import 'package:darttu_client/services/auth/session_repository.dart';
import 'package:darttu_client/services/auth/server_connect.dart';
import 'package:darttu_client/services/network/socket_client.dart';
import 'package:darttu_client/ui/screen.dart';
import 'package:darttu_client/ui/terminal/keys.dart';

final _menuItems = <String>["공식 서버에 연결", "커스텀 호스트 서버에 연결"];

Widget menuComponent(AppState state) {
  final isCustomServer = state.getOrDefault<int>(
    "serverSelection.isCustomServer",
    0,
  );
  return Center(
    child: Card(
      child: Menu(
        items: _menuItems,
        selectedIndex: isCustomServer,
        foregroundColor: TerminalColor.white,
        selectedForegroundColor: TerminalColor.black,
        selectedBackgroundColor: TerminalColor.brightCyan,
      ),
      title: "서버 종류 선택",
    ),
    height: const FlexHeight(3),
  );
}

Widget loadingRow(AppState state) {
  final frame = state.getOrDefault<int>("ui.frame", 0);
  final message = state.get<String>("serverSelection.message");
  if (message == null) {
    return Center(child: Text(""), height: const FlexHeight(1));
  }

  return Center(
    child: Row(
      gap: 1,
      height: const AutoHeight(),
      children: [
        SmallSpinner(frame: frame, foregroundColor: TerminalColor.brightCyan),
        Text(message, foregroundColor: TerminalColor.white),
      ],
    ),
    height: const FlexHeight(1),
  );
}

final class ServerSelection implements AppScreen {
  final AuthClient _authClient;
  final SessionRepository _sessionRepository;
  final ServerConnectService _serverConnect;
  final AppSocketClient _socket;

  ServerSelection({
    required AuthClient authClient,
    required SessionRepository sessionRepository,
    required ServerConnectService serverConnect,
    required AppSocketClient socket,
  }) : _authClient = authClient,
       _sessionRepository = sessionRepository,
       _serverConnect = serverConnect,
       _socket = socket;

  @override
  Widget build(AppState state) {
    return Column(
      children: [
        Spacer(),
        Center(child: menuComponent(state), height: const FlexHeight(1)),
        Spacer(),
        loadingRow(state),
      ],
    );
  }

  @override
  void handleInput(String input, AppState state, AppController controller) {
    var currentIndex = state.getOrDefault("serverSelection.isCustomServer", 0);
    if (input == Keys.arrowUp) {
      currentIndex -= 1;
      currentIndex %= _menuItems.length;

      controller.setValue<int>("serverSelection.isCustomServer", currentIndex);
    } else if (input == Keys.arrowDown) {
      currentIndex += 1;
      currentIndex %= _menuItems.length;

      controller.setValue<int>("serverSelection.isCustomServer", currentIndex);
    } else if (Keys.isEnter(input)) {
      switch (currentIndex) {
        case 0:
          unawaited(_connectOfficialServer(controller));
          return;
        case 1:
          controller.setValue<String>(
            "serverSelection.message",
            '현재는 커스텀 서버 기능을 지원하지 않습니다.',
          );
          return;
      }
    }
  }

  @override
  void onEnter(AppState state, AppController controller) {
    controller.setValue<int>("serverSelection.isCustomServer", 0);
    controller.setValue<String>("serverSelection.message", null);
  }

  @override
  void onExit(AppState state, AppController controller) {
    controller.setValue<String>('serverSelection.message', null);
  }

  Future<void> _connectOfficialServer(AppController controller) async {
    controller.setValue<String>('serverSelection.message', '서버 상태를 확인하는 중...');

    const host = officialServerHost;
    final healthy = await _authClient.healthCheck(
      _serverConnect.healthUri(host: host),
    );
    if (!healthy) {
      controller.setValue<String>(
        'serverSelection.message',
        '서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.',
      );
      return;
    }

    controller.setValue<String>('server.host', host);
    controller.setValue<int>('server.port', null);

    final sessionToken = controller.state.get<String>('auth.sessionToken');
    if (sessionToken != null && sessionToken.isNotEmpty) {
      controller.setValue<String>(
        'serverSelection.message',
        '기존 세션을 확인하는 중...',
      );
      final sessionResult = await _authClient.session(
        uri: _serverConnect.sessionUri(host: host),
        sessionToken: sessionToken,
      );

      if (sessionResult.statusCode == 200) {
        controller.setValue<int>(
          'auth.userId',
          sessionResult.body['userId'] as int?,
        );
        controller.setValue<String>(
          'auth.username',
          sessionResult.body['username']?.toString(),
        );
        controller.setScreenState(ScreenState.roomList);
        return;
      }

      controller.setValue<String>('auth.sessionToken', null);
      controller.setValue<int>('auth.userId', null);
      controller.setValue<String>('auth.username', null);
      await _sessionRepository.clear();
      await _socket.disconnect();
    }

    controller.setScreenState(ScreenState.auth);
  }
}
