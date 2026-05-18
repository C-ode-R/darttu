import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../repositories/auth.dart';

final class AuthResult {
  final int statusCode;
  final Map<String, Object?> body;

  const AuthResult({required this.statusCode, required this.body});
}

final class AuthService {
  final AuthRepo _repo;
  final Random _random = Random.secure();

  AuthService({required AuthRepo repo}) : _repo = repo;

  Map<String, Object?> health() {
    return {'status': 'ok'};
  }

  Future<AuthResult> signup({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty || password.isEmpty) {
      return const AuthResult(
        statusCode: 400,
        body: {'error': 'invalid_credentials'},
      );
    }

    final existingUser = await _repo.findByUsername(normalizedUsername);
    if (existingUser != null) {
      return const AuthResult(
        statusCode: 409,
        body: {'error': 'username_already_exists'},
      );
    }

    final salt = _newSalt();
    final passwordHash = _hashPassword(password, salt);
    final user = await _repo.createUser(
      username: normalizedUsername,
      passwordHash: passwordHash,
      passwordSalt: salt,
    );
    final sessionToken = await _createSessionToken(user.id);

    return AuthResult(
      statusCode: 201,
      body: {
        'userId': user.id,
        'username': user.username,
        'sessionToken': sessionToken,
      },
    );
  }

  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty || password.isEmpty) {
      return const AuthResult(
        statusCode: 400,
        body: {'error': 'invalid_credentials'},
      );
    }

    final user = await _repo.findByUsername(normalizedUsername);
    if (user == null) {
      return const AuthResult(
        statusCode: 401,
        body: {'error': 'invalid_username_or_password'},
      );
    }

    final passwordHash = _hashPassword(password, user.passwordSalt);
    if (passwordHash != user.passwordHash) {
      return const AuthResult(
        statusCode: 401,
        body: {'error': 'invalid_username_or_password'},
      );
    }
    final sessionToken = await _createSessionToken(user.id);

    return AuthResult(
      statusCode: 200,
      body: {
        'userId': user.id,
        'username': user.username,
        'sessionToken': sessionToken,
      },
    );
  }

  Future<AuthResult> session(String token) async {
    if (token.isEmpty) {
      return const AuthResult(
        statusCode: 401,
        body: {'error': 'session_required'},
      );
    }

    final session = await _repo.findSessionByToken(token);
    if (session == null) {
      return const AuthResult(
        statusCode: 401,
        body: {'error': 'invalid_session'},
      );
    }

    final user = await _repo.findById(session.userId);
    if (user == null) {
      return const AuthResult(
        statusCode: 401,
        body: {'error': 'invalid_session'},
      );
    }

    return AuthResult(
      statusCode: 200,
      body: {
        'userId': user.id,
        'username': user.username,
        'sessionToken': session.token,
      },
    );
  }

  String _newSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  Future<String> _createSessionToken(int userId) async {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    final token = base64Url.encode(bytes);
    await _repo.createSession(userId: userId, token: token);
    return token;
  }
}
