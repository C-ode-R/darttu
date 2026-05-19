import '../repositories/auth.dart';

abstract interface class SessionValidator {
  Future<AuthUser?> validate(String token);
}

final class AuthSessionValidator implements SessionValidator {
  final AuthRepo _repo;

  AuthSessionValidator({required AuthRepo repo}) : _repo = repo;

  @override
  Future<AuthUser?> validate(String token) async {
    if (token.isEmpty) return null;

    final session = await _repo.findSessionByToken(token);
    if (session == null) return null;

    return _repo.findById(session.userId);
  }
}
