import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';

final class SizedBox extends Widget {
  final int? width;
  final int? height;
  final Widget? child;

  SizedBox({this.width, this.height, this.child});

  @override
  Size performLayout(Constraints constraints) {
    final resolvedWidth = (width ?? constraints.maxWidth).clamp(
      0,
      constraints.maxWidth,
    );
    final resolvedHeight = (height ?? constraints.maxHeight).clamp(
      0,
      constraints.maxHeight,
    );

    if (child != null) {
      child!.layout(
        Constraints(maxWidth: resolvedWidth, maxHeight: resolvedHeight),
      );
    }

    return Size(width: resolvedWidth, height: resolvedHeight);
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    child?.paint(canvas, x, y);
  }
}
