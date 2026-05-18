import 'package:darttu_client/services/auth/server_connect.dart';
import 'package:darttu_client/services/rooms/rooms_api.dart';
import "package:darttu_client/ui/screen_router.dart";
import 'package:darttu_client/services/auth/session_store.dart';
import 'package:darttu_client/ui/tui_app.dart';
import "app_state.dart";
import "app_controller.dart";

const _roomsApi = RoomsApiService();
const _serverConnect = ServerConnectService();

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
      onBeforeQuit: () => _leaveCurrentRoomIfNeeded(state),
      onHeartbeat: () => _sendHeartbeat(state, controller),
    );
    await tuiApp.run();
  }

  Future<void> _leaveCurrentRoomIfNeeded(AppState state) async {
    final roomId = state.get<int>('room.currentRoomId');
    final sessionToken = state.get<String>('auth.sessionToken');
    final host = state.get<String>('server.host');

    if (roomId == null ||
        sessionToken == null ||
        sessionToken.isEmpty ||
        host == null ||
        host.isEmpty) {
      return;
    }

    await _roomsApi.leaveRoom(
      uri: _serverConnect.leaveRoomUri(
        roomId: roomId,
        host: host,
        port: state.get<int>('server.port'),
      ),
      sessionToken: sessionToken,
    );
  }

  Future<void> _sendHeartbeat(AppState state, AppController controller) async {
    final sessionToken = state.get<String>('auth.sessionToken');
    final host = state.get<String>('server.host');

    if (sessionToken == null ||
        sessionToken.isEmpty ||
        host == null ||
        host.isEmpty) {
      return;
    }

    final result = await _roomsApi.heartbeat(
      uri: _serverConnect.heartbeatUri(
        host: host,
        port: state.get<int>('server.port'),
      ),
      sessionToken: sessionToken,
    );

    if (result.statusCode == 401) {
      controller.setValue<int>('auth.userId', null);
      controller.setValue<String>('auth.username', null);
      controller.setValue<String>('auth.sessionToken', null);
      await const SessionStore().clear();
      controller.setValue<String>('auth.message', '세션이 만료되어 다시 로그인해야 합니다.');
      controller.setScreenState(ScreenState.auth);
    }
  }
}
