import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../database/database.dart';
import '../repositories/auth.dart';
import '../repositories/rooms.dart';
import '../routes/auth.dart';
import '../routes/rooms.dart';
import '../routes/router.dart';
import '../services/auth.dart';
import '../services/rooms.dart';

final class Server {
  late final Handler _handler;
  final AppDatabase _database;

  Server({String databasePath = 'darttu_server.sqlite'})
    : _database = AppDatabase(databasePath) {
    final authRepo = DriftAuthRepo(database: _database);
    final authService = AuthService(repo: authRepo);
    final authRoute = AuthRoute(service: authService);
    final roomsRepo = DriftRoomsRepo(database: _database);
    final roomsService = RoomsService(authRepo: authRepo, roomsRepo: roomsRepo);
    final roomsRoute = RoomsRoute(service: roomsService);

    final pipeline = Pipeline().addMiddleware(_logRequests());
    _handler = pipeline.addHandler(
      Router(authRoute: authRoute, roomsRoute: roomsRoute).handler,
    );
  }

  Handler get handler {
    return _handler;
  }

  Future<HttpServer> serve({String host = '0.0.0.0', int port = 8080}) {
    return shelf_io.serve(handler, host, port);
  }

  Future<void> close() {
    return _database.closeConnection();
  }

  Middleware _logRequests() {
    return (innerHandler) {
      return (request) async {
        final startedAt = DateTime.now();
        stdout.writeln(
          '[${startedAt.toIso8601String()}] -> ${request.method} /${request.url.path}',
        );

        try {
          final response = await innerHandler(request);
          final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
          stdout.writeln(
            '[${DateTime.now().toIso8601String()}] <- ${response.statusCode} ${request.method} /${request.url.path} (${elapsed}ms)',
          );
          return response;
        } on Object catch (error, stackTrace) {
          stdout.writeln(
            '[${DateTime.now().toIso8601String()}] !! ${request.method} /${request.url.path} failed: $error',
          );
          stderr.writeln(stackTrace);
          rethrow;
        }
      };
    };
  }
}
