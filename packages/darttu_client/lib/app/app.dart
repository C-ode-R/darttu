import 'package:darttu_client/app/client_dependencies.dart';
import "package:darttu_client/ui/screen_router.dart";
import 'package:darttu_client/ui/screen_registry.dart';
import 'package:darttu_client/ui/tui_app.dart';
import "app_state.dart";
import "app_controller.dart";

class DarttuApp {
  final ClientDependencies _dependencies;

  DarttuApp({ClientDependencies? dependencies})
    : _dependencies = dependencies ?? ClientDependencies.defaults();

  Future<void> run() async {
    final state = AppState.initial();
    final storedSession = await _dependencies.sessionRepository.load();
    if (storedSession != null) {
      state.setValue<String>('server.host', storedSession.host);
      state.setValue<int>('server.port', storedSession.port);
      state.setValue<int>('auth.userId', storedSession.userId);
      state.setValue<String>('auth.username', storedSession.username);
      state.setValue<String>('auth.sessionToken', storedSession.sessionToken);
    }

    final controller = AppController(state: state);
    final screenRouter = ScreenRouter(
      state: state,
      controller: controller,
      screenRegistry: ScreenRegistry.defaults(dependencies: _dependencies),
    );

    final tuiApp = TuiApp(
      state: state,
      controller: controller,
      screenRouter: screenRouter,
      onBeforeQuit: () => _dependencies.socketConnection.disconnect(),
    );
    await tuiApp.run();
  }
}
