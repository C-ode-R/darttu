import '../http/http_api.dart';
import 'auth_client.dart';

final class AuthApi implements AuthClient {
  final HttpApiService _http;

  AuthApi({required HttpApiService http}) : _http = http;

  @override
  Future<bool> healthCheck(Uri uri) async {
    try {
      final response = await _http.getJson(uri);
      return response.isOk;
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
