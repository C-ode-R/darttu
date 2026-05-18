import 'dart:convert';
import 'dart:io';

final class ApiResponse {
  final int statusCode;
  final Map<String, Object?> body;

  const ApiResponse({required this.statusCode, required this.body});

  bool get isOk => statusCode >= 200 && statusCode < 300;
}

final class HttpApiService {
  const HttpApiService();

  Future<ApiResponse> getJson(Uri uri) async {
    return getJsonWithHeaders(uri: uri, headers: const {});
  }

  Future<ApiResponse> getJsonWithHeaders({
    required Uri uri,
    required Map<String, String> headers,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      headers.forEach(request.headers.set);
      final response = await request.close();
      final body =
          jsonDecode(await utf8.decoder.bind(response).join())
              as Map<String, Object?>;
      return ApiResponse(statusCode: response.statusCode, body: body);
    } on SocketException {
      return _serverUnreachable();
    } on HttpException {
      return _serverUnreachable();
    } on FormatException {
      return _invalidServerResponse();
    } finally {
      client.close(force: true);
    }
  }

  Future<ApiResponse> postJson({
    required Uri uri,
    required Map<String, Object?> payload,
  }) async {
    return postJsonWithHeaders(uri: uri, payload: payload, headers: const {});
  }

  Future<ApiResponse> postJsonWithHeaders({
    required Uri uri,
    required Map<String, Object?> payload,
    required Map<String, String> headers,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      headers.forEach(request.headers.set);
      request.write(jsonEncode(payload));

      final response = await request.close();
      final body =
          jsonDecode(await utf8.decoder.bind(response).join())
              as Map<String, Object?>;
      return ApiResponse(statusCode: response.statusCode, body: body);
    } on SocketException {
      return _serverUnreachable();
    } on HttpException {
      return _serverUnreachable();
    } on FormatException {
      return _invalidServerResponse();
    } finally {
      client.close(force: true);
    }
  }

  ApiResponse _serverUnreachable() {
    return const ApiResponse(
      statusCode: 503,
      body: {'error': 'server_unreachable'},
    );
  }

  ApiResponse _invalidServerResponse() {
    return const ApiResponse(
      statusCode: 500,
      body: {'error': 'invalid_server_response'},
    );
  }
}
