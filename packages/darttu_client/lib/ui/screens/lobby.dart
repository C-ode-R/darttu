import 'package:darttu_client/app/app_controller.dart';
import 'package:darttu_client/app/app_state.dart';
import 'package:darttu_client/layout/layout.dart';
import 'package:darttu_client/ui/screen.dart';
import 'package:darttu_client/ui/terminal/terminal.dart';

const _menuItems = ['서버 선택', '게임 설명', '게임 종료'];
const _fullLogoLines = [
  '██████╗  █████╗ ██████╗ ████████╗████████╗██╗   ██╗',
  '██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝╚══██╔══╝██║   ██║',
  '██║  ██║███████║██████╔╝   ██║      ██║   ██║   ██║',
  '██║  ██║██╔══██║██╔══██╗   ██║      ██║   ██║   ██║',
  '██████╔╝██║  ██║██║  ██║   ██║      ██║   ╚██████╔╝',
  '╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝      ╚═╝    ╚═════╝',
];
const _compactLogoText = 'DARTTU';

Widget logoComponent() {
  final terminalWidth = getTerminalSize().width;
  final fullLogoWidth = _fullLogoLines
      .map(displayWidth)
      .fold<int>(0, (maxWidth, width) => width > maxWidth ? width : maxWidth);
  final logoText = terminalWidth >= fullLogoWidth
      ? _fullLogoLines.join('\n')
      : _compactLogoText;

  return Center(
    child: Colorize(child: Text(logoText), foregroundColor: TerminalColor.cyan),
    height: const AutoHeight(),
  );
}

Widget sloganComponent() {
  return Colorize(
    child: Center(
      child: Text("Dart로 만든 터미널 PVP 끝말잇기!"),
      height: const AutoHeight(),
    ),
    foregroundColor: TerminalColor.white,
  );
}

Widget menuComponent(AppState state) {
  final currentIndex = state.getOrDefault<int>("lobby.menuSelectedIndex", 0);
  return Center(
    child: Menu(
      items: _menuItems,
      selectedIndex: currentIndex,
      foregroundColor: TerminalColor.white,
      selectedForegroundColor: TerminalColor.black,
      selectedBackgroundColor: TerminalColor.brightCyan,
    ),
    height: const AutoHeight(),
  );
}

Widget messageComponent(AppState state) {
  final message = state.get<String>("lobby.message");
  if (message == null || message.isEmpty) {
    return Spacer(height: 0);
  }

  return Center(
    child: Colorize(
      foregroundColor: TerminalColor.brightBlack,
      child: Text(message),
    ),
    height: const AutoHeight(),
  );
}

final class Lobby implements AppScreen {
  @override
  Widget build(AppState state) {
    return Column(
      children: [
        Spacer(),
        Spacer(),
        logoComponent(),
        Spacer(),
        sloganComponent(),
        Spacer(),
        menuComponent(state),
        Spacer(),
        messageComponent(state),
      ],
    );
  }

  @override
  void handleInput(String input, AppState state, AppController controller) {
    final selectedIndex = state.getOrDefault<int>("lobby.menuSelectedIndex", 0);

    if (input == Keys.arrowUp) {
      final nextIndex =
          (selectedIndex - 1 + _menuItems.length) % _menuItems.length;
      controller.setValue<int>("lobby.menuSelectedIndex", nextIndex);
      return;
    }

    if (input == Keys.arrowDown) {
      final nextIndex = (selectedIndex + 1) % _menuItems.length;
      controller.setValue<int>("lobby.menuSelectedIndex", nextIndex);
      return;
    }

    if (Keys.isEnter(input)) {
      switch (selectedIndex) {
        case 0:
          controller.setScreenState(ScreenState.serverSelection);
          return;
        case 1:
          controller.setValue<String>(
            "lobby.message",
            '방향키로 메뉴를 이동하고 Enter로 선택합니다. Ctrl+C로 종료할 수 있습니다.',
          );
          return;
        case 2:
          controller.quit();
      }
    }
  }

  @override
  void onEnter(AppState state, AppController controller) {
    controller.setValue<int>("lobby.menuSelectedIndex", 0);
  }

  @override
  void onExit(AppState state, AppController controller) {
    // TODO: implement onExit
  }
}
