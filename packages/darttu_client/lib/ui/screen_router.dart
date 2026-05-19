import 'package:darttu_client/app/app_controller.dart';
import 'package:darttu_client/app/app_state.dart';
import 'package:darttu_client/layout/core/render_widget.dart';
import 'package:darttu_client/ui/screen.dart';
import 'package:darttu_client/ui/screen_registry.dart';
import 'package:darttu_client/ui/terminal/terminal_size.dart';

final class ScreenRouter {
  final AppState state;
  final AppController controller;
  final ScreenRegistry _screenRegistry;

  ScreenState? _lastScreen;

  ScreenRouter({
    required this.state,
    required this.controller,
    required ScreenRegistry screenRegistry,
  }) : _screenRegistry = screenRegistry;

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
    final screen = _screenRegistry[state.screenState];

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
      _screenRegistry[previous]?.onExit(state, controller);
    }

    _screenRegistry[current]?.onEnter(state, controller);

    _lastScreen = current;
  }
}
