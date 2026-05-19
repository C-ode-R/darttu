import '../network/socket_client.dart';
import '../http/http_api.dart';
import 'auth_client.dart';

final class AuthApi implements AuthClient {
  final HttpApiService _http;
  final AppSocketClient _socket;

  AuthApi({
    required HttpApiService http,
    required AppSocketClient socket,
  }) : _http = http,
       _socket = socket;

  @override
  Future<bool> healthCheck(Uri uri) async {
    try {
      await _socket.connect(uri: uri);
      final response = await _socket.call(action: 'ping');
      return response.statusCode == 200 && response.body['ok'] == true;
    } on Object {
      return false;
    }
  }

  @override
  Future<ApiResponse> signup({
    required Uri uri,
    required String username,
    required String password,
  }) {
    return _http.postJson(
      uri: uri,
      payload: {'username': username, 'password': password},
    );
  }

  @override
  Future<ApiResponse> login({
    required Uri uri,
    required String username,
    required String password,
  }) {
    return _http.postJson(
      uri: uri,
      payload: {'username': username, 'password': password},
    );
  }

  @override
  Future<ApiResponse> session({
    required Uri uri,
    required String sessionToken,
  }) {
    return _http.getJsonWithHeaders(
      uri: uri,
      headers: {'authorization': 'Bearer $sessionToken'},
    );
  }
}
