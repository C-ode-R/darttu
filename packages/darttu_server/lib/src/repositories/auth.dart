import '../database/database.dart';

final class AuthUser {
  final int id;
  final String username;
  final String passwordHash;
  final String passwordSalt;

  const AuthUser({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.passwordSalt,
  });
}

final class AuthSession {
  final int id;
  final int userId;
  final String token;

  const AuthSession({
    required this.id,
    required this.userId,
    required this.token,
  });
}

abstract interface class AuthRepo {
  Future<AuthUser?> findById(int id);
  Future<AuthUser?> findByUsername(String username);
  Future<AuthSession> createSession({
    required int userId,
    required String token,
  });
  Future<AuthSession?> findSessionByToken(String token);
  Future<AuthUser> createUser({
    required String username,
    required String passwordHash,
    required String passwordSalt,
  });
}

final class DriftAuthRepo implements AuthRepo {
  final AppDatabase _database;

  DriftAuthRepo({required AppDatabase database}) : _database = database;

  @override
  Future<AuthUser> createUser({
    required String username,
    required String passwordHash,
    required String passwordSalt,
  }) async {
    final id = await _database
        .into(_database.users)
        .insert(
          UsersCompanion.insert(
            username: username,
            passwordHash: passwordHash,
            passwordSalt: passwordSalt,
          ),
        );

    return AuthUser(
      id: id,
      username: username,
      passwordHash: passwordHash,
      passwordSalt: passwordSalt,
    );
  }

  @override
  Future<AuthUser?> findById(int id) async {
    final row = await (_database.select(
      _database.users,
    )..where((table) => table.id.equals(id))).getSingleOrNull();

    if (row == null) {
      return null;
    }

    return AuthUser(
      id: row.id,
      username: row.username,
      passwordHash: row.passwordHash,
      passwordSalt: row.passwordSalt,
    );
  }

  @override
  Future<AuthUser?> findByUsername(String username) async {
    final row = await (_database.select(
      _database.users,
    )..where((table) => table.username.equals(username))).getSingleOrNull();

    if (row == null) {
      return null;
    }

    return AuthUser(
      id: row.id,
      username: row.username,
      passwordHash: row.passwordHash,
      passwordSalt: row.passwordSalt,
    );
  }

  @override
  Future<AuthSession> createSession({
    required int userId,
    required String token,
  }) async {
    final id = await _database
        .into(_database.sessions)
        .insert(SessionsCompanion.insert(userId: userId, token: token));

    return AuthSession(id: id, userId: userId, token: token);
  }

  @override
  Future<AuthSession?> findSessionByToken(String token) async {
    final row = await (_database.select(
      _database.sessions,
    )..where((table) => table.token.equals(token))).getSingleOrNull();

    if (row == null) {
      return null;
    }

    return AuthSession(id: row.id, userId: row.userId, token: row.token);
  }
}
