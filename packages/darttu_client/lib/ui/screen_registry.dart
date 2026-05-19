import 'package:darttu_client/app/auth_session_coordinator.dart';
import 'package:darttu_client/app/client_dependencies.dart';
import 'package:darttu_client/app/app_state.dart';
import 'package:darttu_client/ui/screen.dart';
import 'package:darttu_client/ui/screens/auth.dart';
import 'package:darttu_client/ui/screens/lobby.dart';
import 'package:darttu_client/ui/screens/room.dart';
import 'package:darttu_client/ui/screens/room_list.dart';
import 'package:darttu_client/ui/screens/server_selection.dart';

typedef ScreenFactory = AppScreen Function();

final class ScreenRegistry {
  final Map<ScreenState, AppScreen> _screens;

  ScreenRegistry(Map<ScreenState, ScreenFactory> factories)
    : _screens = factories.map(
        (screenState, factory) => MapEntry(screenState, factory()),
      );

  factory ScreenRegistry.defaults({required ClientDependencies dependencies}) {
    final authSessionCoordinator = AuthSessionCoordinator(
      dependencies: dependencies,
    );

    return ScreenRegistry({
      ScreenState.lobby: () => Lobby(),
      ScreenState.serverSelection: () => ServerSelection(
        authClient: dependencies.authClient,
        sessionRepository: dependencies.sessionRepository,
        serverConnect: dependencies.serverConnect,
        socket: dependencies.socket,
      ),
      ScreenState.auth: () => AuthScreen(
        authClient: dependencies.authClient,
        sessionRepository: dependencies.sessionRepository,
        serverConnect: dependencies.serverConnect,
      ),
      ScreenState.roomList: () => RoomListScreen(
        roomsClient: dependencies.roomsClient,
        serverConnect: dependencies.serverConnect,
        authSessionCoordinator: authSessionCoordinator,
        socket: dependencies.socket,
      ),
      ScreenState.room: () => RoomScreen(
        roomsClient: dependencies.roomsClient,
        serverConnect: dependencies.serverConnect,
        authSessionCoordinator: authSessionCoordinator,
      ),
    });
  }

  AppScreen? operator [](ScreenState screenState) => _screens[screenState];
}
