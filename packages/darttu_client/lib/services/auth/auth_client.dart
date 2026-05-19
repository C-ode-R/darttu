import '../http/http_api.dart';

abstract interface class AuthClient {
  Future<bool> healthCheck(Uri uri);

  Future<ApiResponse> signup({
    required Uri uri,
    required String username,
    required String password,
  });

  Future<ApiResponse> login({
    required Uri uri,
    required String username,
    required String password,
  });

  Future<ApiResponse> session({required Uri uri, required String sessionToken});
}
