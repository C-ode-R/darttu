import 'package:darttu_client/app/app_controller.dart';
import 'package:darttu_client/app/app_state.dart';
import 'package:darttu_client/layout/core/render_widget.dart';
import 'package:darttu_client/ui/screen.dart';
import 'package:darttu_client/ui/screens/auth.dart';
import 'package:darttu_client/ui/screens/lobby.dart';
import 'package:darttu_client/ui/screens/room.dart';
import 'package:darttu_client/ui/screens/room_list.dart';
import 'package:darttu_client/ui/screens/server_selection.dart';
import 'package:darttu_client/ui/terminal/terminal_size.dart';

final class ScreenRouter {
  final AppState state;
  final AppController controller;

  late final Map<ScreenState, AppScreen> _screens;

  ScreenState? _lastScreen;

  ScreenRouter({required this.state, required this.controller}) {
    _screens = {
      ScreenState.lobby: Lobby(),
      ScreenState.serverSelection: ServerSelection(),
      ScreenState.auth: AuthScreen(),
      ScreenState.roomList: RoomListScreen(),
      ScreenState.room: RoomScreen(),
    };
  }

  String render() {
    _handleScreenTransition();

    final terminalSize = getTerminalSize();

    final widget = _currentScreen().build(state);

    return renderWidget(
      widget,
      width: terminalSize.width,
      height: terminalSize.height,
    );
  }

  void handleInput(String input) {
    if (_handleGlobalInput(input)) return;

    _currentScreen().handleInput(input, state, controller);
  }

  AppScreen _currentScreen() {
    final screen = _screens[state.screenState];

    if (screen == null) {
      throw StateError('Unknown screen: ${state.screenState}');
    }

    return screen;
  }

  bool _handleGlobalInput(String input) {
    if (input == '\x03') {
      controller.quit();
      return true;
    }

    return false;
  }

  void _handleScreenTransition() {
    final current = state.screenState;

    if (_lastScreen == current) return;

    final previous = _lastScreen;

    if (previous != null) {
      _screens[previous]?.onExit(state, controller);
    }

    _screens[current]?.onEnter(state, controller);

    _lastScreen = current;
  }
}
