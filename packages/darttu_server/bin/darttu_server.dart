import 'dart:io';

import 'package:darttu_server/darttu_server.dart';

Future<void> main(List<String> arguments) async {
  final port = arguments.isEmpty ? 8080 : int.parse(arguments.first);
  final databasePath = arguments.length >= 2
      ? arguments[1]
      : 'darttu_server.sqlite';
  final server = Server(databasePath: databasePath);
  final httpServer = await server.serve(port: port);

  stdout.writeln(
    'darttu_server listening on http://localhost:${httpServer.port}',
  );

  ProcessSignal.sigint.watch().listen((_) async {
    await httpServer.close(force: true);
    await server.close();
    exit(0);
  });
}
