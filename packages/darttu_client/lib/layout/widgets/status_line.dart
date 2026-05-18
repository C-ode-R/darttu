import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';
import '../text/display_width.dart';
import '../text/string_utils.dart';

final class StatusLine extends Widget {
  final String left;
  final String right;

  StatusLine({required this.left, required this.right});

  @override
  Size performLayout(Constraints constraints) {
    return Size(width: constraints.maxWidth, height: 1);
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    final leftWidth = displayWidth(left);
    final rightWidth = displayWidth(right);

    if (leftWidth + rightWidth >= size.width) {
      canvas.write(x, y, truncateDisplay('$left $right', size.width));
      return;
    }

    final gap = size.width - leftWidth - rightWidth;
    canvas.write(x, y, '$left${' ' * gap}$right');
  }
}
