import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'keys.dart';

final class TerminalInput {
  StreamSubscription<List<int>>? _subscription;

  bool _initialized = false;
  bool? _previousEchoMode;
  bool? _previousLineMode;
  final StringBuffer _buffer = StringBuffer();

  Future<void> init({required void Function(String input) onInput}) async {
    if (_initialized) {
      return;
    }

    if (!stdin.hasTerminal) {
      throw StateError('stdin is not a terminal.');
    }

    _previousEchoMode = stdin.echoMode;
    _previousLineMode = stdin.lineMode;

    // 사용자가 입력한 글자가 자동으로 터미널에 찍히지 않게 함.
    stdin.echoMode = false;

    // Enter를 누르기 전에도 키 입력을 즉시 받을 수 있게 함.
    stdin.lineMode = false;

    _subscription = stdin.listen(
      (data) {
        final input = utf8.decode(data, allowMalformed: true);

        _buffer.write(input);
        _drainBuffer(onInput);
      },
      onError: (error, stackTrace) {
        // 여기서는 직접 throw하지 않는 것이 좋습니다.
        // Stream 내부 에러는 앱 전체를 터뜨리기보다 무시하거나
        // 나중에 onError 콜백을 따로 추가해서 처리하는 편이 안전합니다.
      },
      cancelOnError: false,
    );

    _initialized = true;
  }

  Future<void> dispose() async {
    if (!_initialized) {
      return;
    }

    await _subscription?.cancel();
    _subscription = null;

    if (stdin.hasTerminal) {
      if (_previousEchoMode != null) {
        stdin.echoMode = _previousEchoMode!;
      }

      if (_previousLineMode != null) {
        stdin.lineMode = _previousLineMode!;
      }
    }

    _previousEchoMode = null;
    _previousLineMode = null;
    _buffer.clear();
    _initialized = false;
  }

  void _drainBuffer(void Function(String input) onInput) {
    while (_buffer.isNotEmpty) {
      final current = _buffer.toString();

      if (current.startsWith(Keys.escape)) {
        if (current.length == 1) {
          return;
        }

        if (!current.startsWith('\x1B[')) {
          final char = current.substring(0, 1);
          _buffer
            ..clear()
            ..write(current.substring(1));
          onInput(char);
          continue;
        }

        if (current.length < 3) {
          return;
        }

        final sequence = current.substring(0, 3);
        if (_isArrowSequence(sequence)) {
          _buffer
            ..clear()
            ..write(current.substring(3));
          onInput(sequence);
          continue;
        }
      }

      final char = current.substring(0, 1);
      _buffer
        ..clear()
        ..write(current.substring(1));
      onInput(char);
    }
  }

  bool _isArrowSequence(String input) {
    return input == '\x1B[A' ||
        input == '\x1B[B' ||
        input == '\x1B[C' ||
        input == '\x1B[D';
  }
}
