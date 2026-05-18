import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';
import '../style/border.dart';
import '../style/edge_insets.dart';
import '../style/text_align.dart';
import '../style/width.dart';
import '../text/display_width.dart';
import '../text/string_utils.dart';

final class Card extends Widget implements WidthConfigurable {
  final String? title;
  @override
  final Width width;
  final BorderStyle borderStyle;
  final EdgeInsets padding;
  final Widget child;

  Card({
    required this.child,
    this.title,
    this.width = const AutoWidth(),
    this.borderStyle = BorderStyle.single,
    this.padding = const EdgeInsets.all(1),
  });

  @override
  Size performLayout(Constraints constraints) {
    final titleHeight = title == null ? 0 : 2;
    final maxInnerWidth = (constraints.maxWidth - 2).clamp(
      0,
      constraints.maxWidth,
    );
    final childMaxHeight =
        (constraints.maxHeight - 2 - titleHeight - padding.vertical).clamp(
          0,
          constraints.maxHeight,
        );
    final titleWidth = title == null ? 0 : displayWidth(title!);
    final childMaxWidth = (maxInnerWidth - padding.horizontal).clamp(
      0,
      maxInnerWidth,
    );

    if (width case AutoWidth()) {
      final childSize = child.layout(
        Constraints(maxWidth: childMaxWidth, maxHeight: childMaxHeight),
      );
      final naturalWidth =
          (childSize.width + padding.horizontal > titleWidth
              ? childSize.width + padding.horizontal
              : titleWidth) +
          2;

      return Size(
        width: naturalWidth.clamp(0, constraints.maxWidth),
        height: childSize.height + padding.vertical + 2 + titleHeight,
      );
    }

    final cardWidth = switch (width) {
      FillWidth() || ExpandWidth() || FlexWidth() => constraints.maxWidth,
      _ => width.resolve(constraints.maxWidth),
    };
    final innerWidth = (cardWidth - 2).clamp(0, cardWidth);
    final childInnerWidth = (innerWidth - padding.horizontal).clamp(
      0,
      innerWidth,
    );
    final childSize = child.layout(
      Constraints(maxWidth: childInnerWidth, maxHeight: childMaxHeight),
    );

    return Size(
      width: cardWidth,
      height: childSize.height + padding.vertical + 2 + titleHeight,
    );
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    final border = BorderChars.fromStyle(borderStyle);
    final innerWidth = size.width - 2;
    final bottomY = y + size.height - 1;

    canvas.write(
      x,
      y,
      '${border.topLeft}${border.horizontal * innerWidth}${border.topRight}',
    );

    var cursorY = y + 1;

    if (title != null) {
      canvas.write(
        x,
        cursorY,
        '${border.vertical}${alignText(title!, innerWidth, align: TextAlign.center)}${border.vertical}',
      );
      cursorY++;

      canvas.write(
        x,
        cursorY,
        '${border.leftJoin}${border.horizontal * innerWidth}${border.rightJoin}',
      );
      cursorY++;
    }

    for (var row = cursorY; row < bottomY; row++) {
      canvas.write(
        x,
        row,
        '${border.vertical}${' ' * innerWidth}${border.vertical}',
      );
    }

    child.paint(canvas, x + 1 + padding.left, cursorY + padding.top);

    canvas.write(
      x,
      bottomY,
      '${border.bottomLeft}${border.horizontal * innerWidth}${border.bottomRight}',
    );
  }
}
