import '../style/color.dart';
import '../text/display_width.dart';

final class Canvas {
  final int width;
  final int height;

  late final List<List<_CanvasCell>> _cells;
  final List<_CanvasStyle> _styleStack = [const _CanvasStyle()];

  Canvas({required this.width, required this.height}) {
    _cells = List.generate(
      height,
      (_) => List.generate(width, (_) => const _CanvasCell()),
    );
  }

  void write(
    int x,
    int y,
    String text, {
    TerminalColor? foregroundColor,
    TerminalColor? backgroundColor,
  }) {
    if (y < 0 || y >= height) return;

    var cursorX = x;
    final effectiveStyle = _styleStack.last.merge(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
    );

    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final charWidth = isWideChar(char) ? 2 : 1;

      if (cursorX >= width) break;
      if (cursorX + charWidth > width) break;

      if (cursorX >= 0) {
        _cells[y][cursorX] = _CanvasCell(
          char: char,
          foregroundColor: effectiveStyle.foregroundColor,
          backgroundColor: effectiveStyle.backgroundColor,
        );

        if (charWidth == 2 && cursorX + 1 < width) {
          _cells[y][cursorX + 1] = _CanvasCell(
            isContinuation: true,
            foregroundColor: effectiveStyle.foregroundColor,
            backgroundColor: effectiveStyle.backgroundColor,
          );
        }
      }

      cursorX += charWidth;
    }
  }

  void fillRect(
    int x,
    int y,
    int rectWidth,
    int rectHeight, {
    String char = ' ',
    TerminalColor? foregroundColor,
    TerminalColor? backgroundColor,
  }) {
    for (var row = 0; row < rectHeight; row++) {
      write(
        x,
        y + row,
        char * rectWidth,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
      );
    }
  }

  void withColors({
    TerminalColor? foregroundColor,
    TerminalColor? backgroundColor,
    required void Function() paint,
  }) {
    _styleStack.add(
      _styleStack.last.merge(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
      ),
    );

    try {
      paint();
    } finally {
      _styleStack.removeLast();
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    _CanvasStyle currentStyle = const _CanvasStyle();

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final cell = _cells[y][x];
        if (cell.isContinuation) {
          continue;
        }

        final nextStyle = _CanvasStyle(
          foregroundColor: cell.foregroundColor,
          backgroundColor: cell.backgroundColor,
        );

        if (nextStyle != currentStyle) {
          buffer.write(_ansiCodeFor(nextStyle));
          currentStyle = nextStyle;
        }

        buffer.write(cell.char);
      }

      if (y != height - 1) {
        if (currentStyle != const _CanvasStyle()) {
          buffer.write('\x1B[0m');
          currentStyle = const _CanvasStyle();
        }
        buffer.write('\n');
      }
    }

    if (currentStyle != const _CanvasStyle()) {
      buffer.write('\x1B[0m');
    }

    return buffer.toString();
  }

  String _ansiCodeFor(_CanvasStyle style) {
    if (style == const _CanvasStyle()) {
      return '\x1B[0m';
    }

    final codes = <String>[];

    if (style.foregroundColor != null) {
      codes.add(TerminalColors.foregroundCode(style.foregroundColor!));
    }
    if (style.backgroundColor != null) {
      codes.add(TerminalColors.backgroundCode(style.backgroundColor!));
    }

    if (codes.isEmpty) {
      return '\x1B[0m';
    }

    return '\x1B[${codes.join(';')}m';
  }
}

final class _CanvasCell {
  final String char;
  final TerminalColor? foregroundColor;
  final TerminalColor? backgroundColor;
  final bool isContinuation;

  const _CanvasCell({
    this.char = ' ',
    this.foregroundColor,
    this.backgroundColor,
    this.isContinuation = false,
  });
}

final class _CanvasStyle {
  final TerminalColor? foregroundColor;
  final TerminalColor? backgroundColor;

  const _CanvasStyle({this.foregroundColor, this.backgroundColor});

  _CanvasStyle merge({
    TerminalColor? foregroundColor,
    TerminalColor? backgroundColor,
  }) {
    return _CanvasStyle(
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _CanvasStyle &&
        other.foregroundColor == foregroundColor &&
        other.backgroundColor == backgroundColor;
  }

  @override
  int get hashCode => Object.hash(foregroundColor, backgroundColor);
}
