import 'package:darttu_client/app/app_controller.dart';
import 'package:darttu_client/app/app_state.dart';
import 'package:darttu_client/layout/core/widget.dart';

abstract interface class AppScreen {
  Widget build(AppState state);

  void handleInput(String input, AppState state, AppController controller);

  void onEnter(AppState state, AppController controller) {}

  void onExit(AppState state, AppController controller) {}
}
