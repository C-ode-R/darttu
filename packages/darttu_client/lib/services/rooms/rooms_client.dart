import 'models.dart';

abstract interface class RoomsClient {
  Future<RoomsApiResult> fetchLobby({
    required Uri uri,
    required String sessionToken,
  });

  Future<RoomsApiResult> createRoom({
    required Uri uri,
    required String sessionToken,
    required String name,
    int maxPlayers = 4,
  });

  Future<RoomsApiResult> joinRoom({
    required Uri uri,
    required String sessionToken,
    required int roomId,
  });

  Future<RoomsApiResult> fetchRoom({
    required Uri uri,
    required String sessionToken,
    required int roomId,
  });

  Future<RoomsApiResult> leaveRoom({
    required Uri uri,
    required String sessionToken,
    required int roomId,
  });

  Future<RoomsApiResult> toggleReady({
    required Uri uri,
    required String sessionToken,
    required int roomId,
  });

  Future<RoomsApiResult> startGame({
    required Uri uri,
    required String sessionToken,
    required int roomId,
  });
}
