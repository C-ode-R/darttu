import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';
import '../style/edge_insets.dart';

final class Margin extends Widget {
  final EdgeInsets margin;
  final Widget child;

  Margin({required this.margin, required this.child});

  @override
  Size performLayout(Constraints constraints) {
    final childSize = child.layout(
      constraints.shrink(
        horizontal: margin.horizontal,
        vertical: margin.vertical,
      ),
    );

    return Size(
      width: childSize.width + margin.horizontal,
      height: childSize.height + margin.vertical,
    );
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    child.paint(canvas, x + margin.left, y + margin.top);
  }
}
