import 'dart:async';
import 'dart:io';

import 'package:darttu_client/app/app_controller.dart';
import 'package:darttu_client/app/app_state.dart';
import 'package:darttu_client/ui/screen_router.dart';
import 'package:darttu_client/ui/terminal/terminal_input.dart';
import 'package:darttu_client/ui/terminal/terminal_renderer.dart';

final class TuiApp {
  static const _animationFrameKey = 'ui.frame';
  static const _animationFrameInterval = Duration(milliseconds: 100);

  final AppState state;
  final AppController controller;
  final ScreenRouter screenRouter;
  final Future<void> Function()? onBeforeQuit;

  final TerminalRenderer renderer;
  final TerminalInput input;

  bool _running = false;
  bool _renderScheduled = false;
  bool _disposed = false;
  Timer? _animationTimer;
  StreamSubscription<ProcessSignal>? _sigintSubscription;
  StreamSubscription<ProcessSignal>? _sigtermSubscription;
  bool _quitRequested = false;

  TuiApp({
    required this.state,
    required this.controller,
    required this.screenRouter,
    this.onBeforeQuit,
    TerminalRenderer? renderer,
    TerminalInput? input,
  }) : renderer = renderer ?? TerminalRenderer(),
       input = input ?? TerminalInput();

  Future<void> run() async {
    if (_running) {
      throw StateError('TuiApp is already running.');
    }

    _running = true;

    try {
      renderer.init();

      controller.onStateChanged = scheduleRender;
      controller.onQuit = () {
        unawaited(_requestQuit());
      };
      controller.setValue<int>(_animationFrameKey, 0);
      _startAnimationTick();
      _installSignalHandlers();

      await input.init(onInput: _handleInput);

      // 최초 화면 렌더링
      scheduleRender();

      // 앱 생존 루프
      while (_running) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    } finally {
      await dispose();
    }
  }

  void _handleInput(String key) {
    if (!_running || _disposed) {
      return;
    }

    screenRouter.handleInput(key);
    scheduleRender();
  }

  void scheduleRender() {
    if (!_running || _disposed) {
      return;
    }

    if (_renderScheduled) {
      return;
    }

    _renderScheduled = true;

    scheduleMicrotask(() {
      _renderScheduled = false;

      if (!_running || _disposed) {
        return;
      }

      render();
    });
  }

  void render() {
    if (!_running || _disposed) {
      return;
    }

    final output = screenRouter.render();
    renderer.render(output);
  }

  void quit() {
    _running = false;
  }

  Future<void> _requestQuit() async {
    if (_quitRequested) {
      return;
    }

    _quitRequested = true;

    try {
      await onBeforeQuit?.call();
    } finally {
      quit();
    }
  }

  void _startAnimationTick() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(_animationFrameInterval, (_) {
      if (!_running || _disposed) {
        return;
      }

      final currentFrame = state.getOrDefault<int>(_animationFrameKey, 0);
      controller.setValue<int>(_animationFrameKey, currentFrame + 1);
    });
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _animationTimer?.cancel();
    _animationTimer = null;
    await _sigintSubscription?.cancel();
    _sigintSubscription = null;
    await _sigtermSubscription?.cancel();
    _sigtermSubscription = null;

    controller.onStateChanged = null;
    controller.onQuit = null;

    await input.dispose();
    renderer.dispose();
  }

  void _installSignalHandlers() {
    _sigintSubscription?.cancel();
    _sigtermSubscription?.cancel();

    _sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
      unawaited(_requestQuit());
    });

    _sigtermSubscription = ProcessSignal.sigterm.watch().listen((_) {
      unawaited(_requestQuit());
    });
  }
}
