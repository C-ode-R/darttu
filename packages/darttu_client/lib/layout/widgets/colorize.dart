import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';
import '../style/color.dart';

final class Colorize extends Widget {
  final TerminalColor? foregroundColor;
  final TerminalColor? backgroundColor;
  final Widget child;

  Colorize({required this.child, this.foregroundColor, this.backgroundColor});

  @override
  Size performLayout(Constraints constraints) {
    return child.layout(constraints);
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    if (backgroundColor != null) {
      canvas.fillRect(
        x,
        y,
        size.width,
        size.height,
        backgroundColor: backgroundColor,
      );
    }

    canvas.withColors(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      paint: () => child.paint(canvas, x, y),
    );
  }
}
