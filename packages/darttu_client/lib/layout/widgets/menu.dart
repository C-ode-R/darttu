import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';
import '../style/color.dart';
import '../text/display_width.dart';
import '../text/string_utils.dart';

final class Menu extends Widget {
  final List<String> items;
  final int selectedIndex;
  final TerminalColor? foregroundColor;
  final TerminalColor? backgroundColor;
  final TerminalColor? selectedForegroundColor;
  final TerminalColor? selectedBackgroundColor;

  Menu({
    required this.items,
    required this.selectedIndex,
    this.foregroundColor,
    this.backgroundColor,
    this.selectedForegroundColor,
    this.selectedBackgroundColor,
  });

  @override
  Size performLayout(Constraints constraints) {
    final naturalWidth = items
        .map((item) => displayWidth(item) + 2)
        .fold<int>(0, (max, width) => width > max ? width : max);

    return Size(
      width: naturalWidth.clamp(0, constraints.maxWidth),
      height: items.length.clamp(0, constraints.maxHeight),
    );
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    for (var i = 0; i < items.length && i < size.height; i++) {
      final isSelected = i == selectedIndex;
      final prefix = isSelected ? '>' : ' ';
      final line = '$prefix ${items[i]}';

      canvas.write(
        x,
        y + i,
        alignText(line, size.width),
        foregroundColor: isSelected
            ? selectedForegroundColor ?? foregroundColor
            : foregroundColor,
        backgroundColor: isSelected
            ? selectedBackgroundColor ?? backgroundColor
            : backgroundColor,
      );
    }
  }
}
