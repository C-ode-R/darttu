import '../database/database.dart';
import '../repositories/auth.dart';
import '../repositories/rooms.dart';
import '../routes/auth.dart';
import '../routes/http.dart';
import '../routes/rooms.dart';
import '../routes/socket.dart';
import '../services/auth.dart';
import '../services/room_membership.dart';
import '../services/rooms.dart';
import '../services/session_validator.dart';
import '../middlewares/auth.dart';
import '../middlewares/presence.dart';
import 'server.dart';
import 'socket_connection_lifecycle.dart';
import 'socket_session_factory.dart';

final class ServerBootstrap {
  static Server build({String databasePath = 'darttu_server.sqlite'}) {
    final database = AppDatabase(databasePath);
    final authRepo = DriftAuthRepo(database: database);
    final presenceRepo = DriftPresenceRepo(db: database);
    final roomRepo = DriftRoomRepo(db: database, presence: presenceRepo);
    final memberRepo = DriftRoomMemberRepo(db: database);

    final authService = AuthService(repo: authRepo);
    final sessionValidator = AuthSessionValidator(repo: authRepo);

    late final Server server;
    final membership = RoomMembershipService(
      rooms: roomRepo,
      members: memberRepo,
      presence: presenceRepo,
      onRoomChanged: () => server.broadcastLobby(),
    );
    final roomsService = RoomsService(
      rooms: roomRepo,
      membership: membership,
    );

    final roomMiddlewares = [
      requireAuth(sessionValidator),
      trackPresence(membership, roomRepo),
    ];

    server = Server(
      httpRouter: HttpRouter(AuthHttpRoutes(service: authService).definitions),
      socketRouter: SocketRouter(
        RoomsSocketRoutes(rooms: roomsService).definitions,
        middlewares: roomMiddlewares,
      ),
      socketSessionFactory: AuthSocketSessionFactory(validator: sessionValidator),
      socketConnectionLifecycle: RoomsSocketConnectionLifecycle(
        membership: membership,
      ),
      roomsService: roomsService,
      onClose: database.closeConnection,
    );

    return server;
  }
}
