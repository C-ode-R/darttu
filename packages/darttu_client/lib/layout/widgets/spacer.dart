import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';

final class Spacer extends Widget {
  final int height;

  Spacer({this.height = 1});

  @override
  Size performLayout(Constraints constraints) {
    return Size(width: 0, height: height.clamp(0, constraints.maxHeight));
  }

  @override
  void paint(Canvas canvas, int x, int y) {}
}
