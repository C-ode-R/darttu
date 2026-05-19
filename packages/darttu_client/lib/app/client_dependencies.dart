import 'package:darttu_client/services/auth/auth_api.dart';
import 'package:darttu_client/services/auth/auth_client.dart';
import 'package:darttu_client/services/auth/server_connect.dart';
import 'package:darttu_client/services/auth/session_repository.dart';
import 'package:darttu_client/services/auth/session_store.dart';
import 'package:darttu_client/services/http/http_api.dart';
import 'package:darttu_client/services/network/socket_client.dart';
import 'package:darttu_client/services/network/socket_connection.dart';
import 'package:darttu_client/services/rooms/rooms_api.dart';
import 'package:darttu_client/services/rooms/rooms_client.dart';

final class ClientDependencies {
  final AuthClient authClient;
  final RoomsClient roomsClient;
  final SessionRepository sessionRepository;
  final ServerConnectService serverConnect;
  final SocketConnection socketConnection;

  const ClientDependencies({
    required this.authClient,
    required this.roomsClient,
    required this.sessionRepository,
    required this.serverConnect,
    required this.socketConnection,
  });

  factory ClientDependencies.defaults() {
    final socket = AppSocketClient();
    final http = const HttpApiService();
    return ClientDependencies(
      authClient: AuthApi(http: http),
      roomsClient: RoomsApi(socket: socket),
      sessionRepository: const SessionStore(),
      serverConnect: const ServerConnectService(),
      socketConnection: socket,
    );
  }
}
