import '../http/http_api.dart';

final class AuthApiService {
  final HttpApiService _http;

  const AuthApiService({HttpApiService http = const HttpApiService()})
    : _http = http;

  Future<bool> healthCheck(Uri uri) async {
    final response = await _http.getJson(uri);
    return response.statusCode == 200 && response.body['status'] == 'ok';
  }

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
