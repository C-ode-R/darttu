import 'canvas.dart';
import 'constraints.dart';
import 'size.dart';

abstract class Widget {
  Size? _size;

  Size get size {
    final value = _size;

    if (value == null) {
      throw StateError('Widget has not been laid out yet.');
    }

    return value;
  }

  Size layout(Constraints constraints) {
    _size = performLayout(constraints);
    return _size!;
  }

  Size performLayout(Constraints constraints);

  void paint(Canvas canvas, int x, int y);
}
