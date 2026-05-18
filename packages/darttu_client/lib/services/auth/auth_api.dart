import '../http/http_api.dart';
import '../network/socket_client.dart';

final class AuthApiService {
  final AppSocketClient _socket;

  AuthApiService({AppSocketClient? socket})
    : _socket = socket ?? appSocketClient;

  Future<bool> healthCheck(Uri uri) async {
    try {
      await _socket.connect(uri: uri);
      final response = await _socket.call(action: 'ping');
      return response.statusCode == 200 && response.body['ok'] == true;
    } on Object {
      return false;
    }
  }

  Future<ApiResponse> signup({
    required Uri uri,
    required String username,
    required String password,
  }) {
    return _socket.call(
      action: 'signup',
      payload: {'username': username, 'password': password},
    );
  }

  Future<ApiResponse> login({
    required Uri uri,
    required String username,
    required String password,
  }) {
    return _socket.call(
      action: 'login',
      payload: {'username': username, 'password': password},
    );
  }

  Future<ApiResponse> session({
    required Uri uri,
    required String sessionToken,
  }) {
    return _socket.call(
      action: 'session',
      payload: {'sessionToken': sessionToken},
    );
  }
}
