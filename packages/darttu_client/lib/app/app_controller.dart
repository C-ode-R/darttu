import "app_state.dart";

class AppController {
  final AppState state;
  void Function()? onStateChanged;
  void Function()? onQuit;

  AppController({required this.state});

  void setValue<T>(String key, T? value) {
    final changed = state.setValue<T>(key, value);
    if (!changed) {
      return;
    }

    onStateChanged?.call();
  }

  void setScreenState(ScreenState newScreenState) {
    if (newScreenState == state.screenState) return;
    state.screenState = newScreenState;
    onStateChanged?.call();
  }

  void quit({int returnValue = 0}) {
    final quitHandler = onQuit;
    if (quitHandler != null) {
      quitHandler();
      return;
    }
  }
}
