import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';
import '../style/color.dart';

final class SmallSpinner extends Widget {
  final int frame;
  final TerminalColor? foregroundColor;
  final TerminalColor? backgroundColor;

  SmallSpinner({
    required this.frame,
    this.foregroundColor,
    this.backgroundColor,
  });

  static const List<String> _frames = [
    '⠁',
    '⠂',
    '⠄',
    '⡀',
    '⢀',
    '⠠',
    '⠐',
    '⠈',
    '⠁',
    '⠃',
    '⠇',
    '⡇',
    '⣇',
    '⣧',
    '⣷',
    '⣿',
  ];

  @override
  Size performLayout(Constraints constraints) {
    return Size(
      width: constraints.maxWidth <= 0 ? 0 : 1,
      height: constraints.maxHeight <= 0 ? 0 : 1,
    );
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final index = ((frame % _frames.length) + _frames.length) % _frames.length;
    canvas.write(
      x,
      y,
      _frames[index],
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
    );
  }
}
