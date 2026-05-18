import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';

final class Divider extends Widget {
  final String char;

  Divider({this.char = '─'});

  @override
  Size performLayout(Constraints constraints) {
    return Size(width: constraints.maxWidth, height: 1);
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    canvas.write(x, y, char * size.width);
  }
}
