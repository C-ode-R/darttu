abstract interface class SocketClient {
  Stream<Object?> get events;

  Future<void> connect({required Uri uri});
  Future<void> disconnect();

  Future<void> send(Object? message);
}
