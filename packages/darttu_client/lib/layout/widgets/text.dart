import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';
import '../style/color.dart';
import '../style/text_align.dart';
import '../text/display_width.dart';
import '../text/string_utils.dart';

final class Text extends Widget {
  final String value;
  final TextAlign align;
  final bool expand;
  final TerminalColor? foregroundColor;
  final TerminalColor? backgroundColor;

  Text(
    this.value, {
    this.align = TextAlign.left,
    this.expand = false,
    this.foregroundColor,
    this.backgroundColor,
  });

  List<String> get _lines => value.split('\n');

  @override
  Size performLayout(Constraints constraints) {
    final naturalWidth = _lines.fold<int>(
      0,
      (maxWidth, line) =>
          displayWidth(line) > maxWidth ? displayWidth(line) : maxWidth,
    );
    final width = expand
        ? constraints.maxWidth
        : naturalWidth.clamp(0, constraints.maxWidth);
    final height = _lines.length.clamp(0, constraints.maxHeight);

    return Size(width: width, height: height);
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    for (var index = 0; index < size.height; index++) {
      canvas.write(
        x,
        y + index,
        alignText(_lines[index], size.width, align: align),
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
      );
    }
  }
}
