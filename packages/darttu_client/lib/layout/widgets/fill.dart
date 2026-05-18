import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';

final class Fill extends Widget {
  final Widget child;

  Fill({required this.child});

  @override
  Size performLayout(Constraints constraints) {
    child.layout(constraints);

    return Size(width: constraints.maxWidth, height: constraints.maxHeight);
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    child.paint(canvas, x, y);
  }
}
