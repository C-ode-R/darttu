import 'dart:async';

import 'package:darttu_client/app/app_controller.dart';
import 'package:darttu_client/app/app_state.dart';
import 'package:darttu_client/layout/layout.dart';
import 'package:darttu_client/services/auth/auth_api.dart';
import 'package:darttu_client/services/auth/session_store.dart';
import 'package:darttu_client/services/auth/server_connect.dart';
import 'package:darttu_client/ui/screen.dart';
import 'package:darttu_client/ui/terminal/keys.dart';

const _authApi = AuthApiService();
const _sessionStore = SessionStore();
const _serverConnect = ServerConnectService();
const _fieldCount = 2;

final class AuthScreen implements AppScreen {
  @override
  Widget build(AppState state) {
    final isSignup = state.getOrDefault<bool>('auth.isSignup', false);
    final focusedField = state.getOrDefault<int>('auth.focusedField', 0);
    final username = state.getOrDefault<String>('auth.usernameInput', '');
    final password = state.getOrDefault<String>('auth.passwordInput', '');
    final message = state.get<String>('auth.message');
    final modeLabel = isSignup ? '회원가입' : '로그인';

    return Column(
      children: [
        Spacer(),
        Center(
          child: Card(
            title: '계정 인증',
            child: Column(
              children: [
                Text(
                  '좌우 방향키로 모드 전환, 상하 방향키로 필드 이동, Enter로 제출',
                  foregroundColor: TerminalColor.brightBlack,
                ),
                SizedBox(height: 1),
                Text(
                  '현재 모드: $modeLabel',
                  foregroundColor: TerminalColor.brightCyan,
                ),
                SizedBox(height: 1),
                InputLine(
                  label: '아이디',
                  value: username,
                  focused: focusedField == 0,
                ),
                InputLine(
                  label: '비밀번호',
                  value: '*' * password.length,
                  focused: focusedField == 1,
                ),
              ],
            ),
          ),
          height: const AutoHeight(),
        ),
        SizedBox(height: 1),
        Center(child: Text(message ?? ''), height: const AutoHeight()),
        Spacer(),
      ],
    );
  }

  @override
  void handleInput(String input, AppState state, AppController controller) {
    final focusedField = state.getOrDefault<int>('auth.focusedField', 0);

    if (input == Keys.arrowLeft || input == Keys.arrowRight) {
      final isSignup = state.getOrDefault<bool>('auth.isSignup', false);
      controller.setValue<bool>('auth.isSignup', !isSignup);
      return;
    }

    if (input == Keys.arrowUp) {
      controller.setValue<int>(
        'auth.focusedField',
        (focusedField - 1 + _fieldCount) % _fieldCount,
      );
      return;
    }

    if (input == Keys.arrowDown) {
      controller.setValue<int>(
        'auth.focusedField',
        (focusedField + 1) % _fieldCount,
      );
      return;
    }

    if (Keys.isBackspace(input)) {
      _editFocusedField(state, controller, (value) {
        if (value.isEmpty) {
          return value;
        }
        return value.substring(0, value.length - 1);
      });
      return;
    }

    if (Keys.isPrintable(input)) {
      _editFocusedField(state, controller, (value) => '$value$input');
      return;
    }

    if (Keys.isEnter(input)) {
      unawaited(_submit(state, controller));
    }
  }

  @override
  void onEnter(AppState state, AppController controller) {
    controller.setValue<bool>(
      'auth.isSignup',
      state.getOrDefault('auth.isSignup', false),
    );
    controller.setValue<int>('auth.focusedField', 0);
    controller.setValue<String>(
      'auth.usernameInput',
      state.getOrDefault('auth.usernameInput', ''),
    );
    controller.setValue<String>('auth.passwordInput', '');
    controller.setValue<String>('auth.message', null);
  }

  @override
  void onExit(AppState state, AppController controller) {}

  void _editFocusedField(
    AppState state,
    AppController controller,
    String Function(String value) transform,
  ) {
    final focusedField = state.getOrDefault<int>('auth.focusedField', 0);
    final key = focusedField == 0 ? 'auth.usernameInput' : 'auth.passwordInput';
    final current = state.getOrDefault<String>(key, '');
    controller.setValue<String>(key, transform(current));
  }

  Future<void> _submit(AppState state, AppController controller) async {
    final username = state.getOrDefault<String>('auth.usernameInput', '');
    final password = state.getOrDefault<String>('auth.passwordInput', '');
    final isSignup = state.getOrDefault<bool>('auth.isSignup', false);
    final host = state.getOrDefault<String>('server.host', 'localhost');
    final port = state.get<int>('server.port');

    if (username.trim().isEmpty || password.isEmpty) {
      controller.setValue<String>('auth.message', '아이디와 비밀번호를 입력해주세요.');
      return;
    }

    controller.setValue<String>(
      'auth.message',
      isSignup ? '회원가입 요청 중...' : '로그인 요청 중...',
    );

    final result = isSignup
        ? await _authApi.signup(
            uri: _serverConnect.signupUri(host: host, port: port),
            username: username,
            password: password,
          )
        : await _authApi.login(
            uri: _serverConnect.loginUri(host: host, port: port),
            username: username,
            password: password,
          );

    if (result.statusCode == 200 || result.statusCode == 201) {
      final userId = result.body['userId'] as int?;
      final usernameValue = result.body['username']?.toString();
      final sessionToken = result.body['sessionToken']?.toString();
      controller.setValue<int>('auth.userId', userId);
      controller.setValue<String>('auth.username', usernameValue);
      controller.setValue<String>('auth.sessionToken', sessionToken);
      if (userId != null &&
          usernameValue != null &&
          sessionToken != null &&
          sessionToken.isNotEmpty) {
        await _sessionStore.save(
          StoredSession(
            host: host,
            port: port,
            userId: userId,
            username: usernameValue,
            sessionToken: sessionToken,
          ),
        );
      }
      controller.setValue<String>(
        'roomList.message',
        '$usernameValue 계정으로 인증되었습니다.',
      );
      controller.setScreenState(ScreenState.roomList);
      return;
    }

    controller.setValue<String>(
      'auth.message',
      _messageForError(result.body['error']?.toString() ?? 'unknown_error'),
    );
  }

  String _messageForError(String error) {
    switch (error) {
      case 'invalid_credentials':
        return '아이디와 비밀번호를 확인해주세요.';
      case 'username_already_exists':
        return '이미 존재하는 아이디입니다.';
      case 'invalid_username_or_password':
        return '아이디 또는 비밀번호가 올바르지 않습니다.';
      case 'invalid_json':
        return '요청 형식이 올바르지 않습니다.';
      case 'server_unreachable':
        return '서버에 연결할 수 없습니다.';
      case 'invalid_server_response':
        return '서버 응답을 해석할 수 없습니다.';
    }

    return error;
  }
}
