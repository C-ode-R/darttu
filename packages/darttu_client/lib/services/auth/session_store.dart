import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'session_repository.dart';

final class StoredSession {
  final String host;
  final int? port;
  final int userId;
  final String username;
  final String sessionToken;

  const StoredSession({
    required this.host,
    required this.port,
    required this.userId,
    required this.username,
    required this.sessionToken,
  });

  Map<String, Object?> toJson() {
    return {
      'host': host,
      'port': port,
      'userId': userId,
      'username': username,
      'sessionToken': sessionToken,
    };
  }

  static StoredSession? fromJson(Map<String, Object?> json) {
    final host = json['host'];
    final port = json['port'];
    final userId = json['userId'];
    final username = json['username'];
    final sessionToken = json['sessionToken'];

    if (host is! String ||
        (port != null && port is! int) ||
        userId is! int ||
        username is! String ||
        sessionToken is! String) {
      return null;
    }

    return StoredSession(
      host: host,
      port: port as int?,
      userId: userId,
      username: username,
      sessionToken: sessionToken,
    );
  }
}

final class SessionStore implements SessionRepository {
  const SessionStore();

  @override
  Future<StoredSession?> load() async {
    try {
      final file = File(_sessionFilePath());
      if (!await file.exists()) {
        return null;
      }

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, Object?>) {
        return null;
      }

      return StoredSession.fromJson(decoded);
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(StoredSession session) async {
    final file = File(_sessionFilePath());
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    try {
      final file = File(_sessionFilePath());
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // Ignore session cleanup errors.
    }
  }

  String _sessionFilePath() {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null || home.isEmpty) {
      return path.join(Directory.current.path, '.darttu_session.json');
    }

    return path.join(home, '.darttu', 'session.json');
  }
}
