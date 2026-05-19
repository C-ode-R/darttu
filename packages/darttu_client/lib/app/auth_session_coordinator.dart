import 'app_controller.dart';
import 'app_state.dart';
import 'client_dependencies.dart';

final class AuthSessionCoordinator {
  final ClientDependencies _dependencies;

  const AuthSessionCoordinator({required ClientDependencies dependencies})
    : _dependencies = dependencies;

  Future<void> expireSession(
    AppController controller, {
    String message = '세션이 만료되어 다시 로그인해야 합니다.',
  }) async {
    controller.setValue<int>('auth.userId', null);
    controller.setValue<String>('auth.username', null);
    controller.setValue<String>('auth.sessionToken', null);
    await _dependencies.sessionRepository.clear();
    await _dependencies.socket.disconnect();
    controller.setValue<String>('auth.message', message);
    controller.setScreenState(ScreenState.auth);
  }
}
