import 'session_store.dart';

abstract interface class SessionRepository {
  Future<StoredSession?> load();

  Future<void> save(StoredSession session);

  Future<void> clear();
}
