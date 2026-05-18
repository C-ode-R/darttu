import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';
import '../style/color.dart';

final class LargeSpinner extends Widget {
  final int frame;
  final TerminalColor? foregroundColor;
  final TerminalColor? backgroundColor;

  LargeSpinner({
    required this.frame,
    this.foregroundColor,
    this.backgroundColor,
  });

  static const List<List<String>> _frames = [
    [' ● ', '   ', '   '],
    ['  ●', '   ', '   '],
    ['   ', '  ●', '   '],
    ['   ', '   ', '  ●'],
    ['   ', '   ', ' ● '],
    ['   ', '   ', '●  '],
    ['   ', '●  ', '   '],
    ['●  ', '   ', '   '],
  ];

  @override
  Size performLayout(Constraints constraints) {
    final resolvedWidth = constraints.maxWidth < 3 ? constraints.maxWidth : 3;
    final resolvedHeight = constraints.maxHeight < 3
        ? constraints.maxHeight
        : 3;
    return Size(width: resolvedWidth, height: resolvedHeight);
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final index = ((frame % _frames.length) + _frames.length) % _frames.length;
    final rows = _frames[index];

    for (var row = 0; row < size.height && row < rows.length; row++) {
      canvas.write(
        x,
        y + row,
        rows[row].substring(0, size.width),
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
      );
    }
  }
}
