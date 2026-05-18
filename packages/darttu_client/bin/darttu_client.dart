import 'package:darttu_client/app/app.dart';

Future<void> main(List<String> args) async {
  final app = DarttuApp();
  await app.run();
}