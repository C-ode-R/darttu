import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';
import '../text/string_utils.dart';

final class InputLine extends Widget {
  final String label;
  final String value;
  final bool focused;

  InputLine({required this.label, required this.value, this.focused = true});

  @override
  Size performLayout(Constraints constraints) {
    return Size(width: constraints.maxWidth, height: 1);
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    final cursor = focused ? '_' : '';
    final text = '$label: $value$cursor';

    canvas.write(x, y, truncateDisplay(text, size.width));
  }
}
