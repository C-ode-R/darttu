import 'dart:convert';

import 'package:shelf/shelf.dart';

Future<Map<String, Object?>?> decodeJsonBody(Request request) async {
  try {
    final body = await request.readAsString();
    if (body.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(body);
    return decoded is Map<String, Object?> ? decoded : null;
  } on FormatException {
    return null;
  }
}

Response jsonResponse(int statusCode, Map<String, Object?> body) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );
}

String bearerToken(Request request) {
  final authorization = request.headers['authorization'];
  if (authorization == null) {
    return '';
  }

  const prefix = 'Bearer ';
  if (!authorization.startsWith(prefix)) {
    return '';
  }

  return authorization.substring(prefix.length).trim();
}
