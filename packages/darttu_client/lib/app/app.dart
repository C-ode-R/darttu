import "package:darttu_client/ui/screen_router.dart";
import 'package:darttu_client/services/auth/session_store.dart';
import 'package:darttu_client/ui/tui_app.dart';
import "app_state.dart";
import "app_controller.dart";

class DarttuApp {
  Future<void> run() async {
    final state = AppState.initial();
    final storedSession = await const SessionStore().load();
    if (storedSession != null) {
      state.setValue<String>('server.host', storedSession.host);
      state.setValue<int>('server.port', storedSession.port);
      state.setValue<int>('auth.userId', storedSession.userId);
      state.setValue<String>('auth.username', storedSession.username);
      state.setValue<String>('auth.sessionToken', storedSession.sessionToken);
    }

    final controller = AppController(state: state);
    final screenRouter = ScreenRouter(state: state, controller: controller);

    final tuiApp = TuiApp(
      state: state,
      controller: controller,
      screenRouter: screenRouter,
    );
    await tuiApp.run();
  }
}
