import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';
import '../style/edge_insets.dart';

final class Padding extends Widget {
  final EdgeInsets padding;
  final Widget child;

  Padding({required this.padding, required this.child});

  @override
  Size performLayout(Constraints constraints) {
    final childSize = child.layout(
      constraints.shrink(
        horizontal: padding.horizontal,
        vertical: padding.vertical,
      ),
    );

    return Size(
      width: childSize.width + padding.horizontal,
      height: childSize.height + padding.vertical,
    );
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    child.paint(canvas, x + padding.left, y + padding.top);
  }
}
