import 'dart:math';

import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';
import '../style/height.dart';

final class Column extends Widget {
  final List<Widget> children;
  final int gap;
  final bool expandWidth;
  late List<bool> _laidOutChildren;

  Column({required this.children, this.gap = 0, this.expandWidth = false});

  @override
  Size performLayout(Constraints constraints) {
    _laidOutChildren = List<bool>.filled(children.length, false);

    final availableHeight = max(
      0,
      constraints.maxHeight - (max(0, children.length - 1) * gap),
    );
    var usedHeight = 0;
    var maxChildWidth = 0;
    var flexTotal = 0;

    for (final child in children) {
      final height = _heightFor(child);
      if (height is FlexHeight) {
        flexTotal += height.flex;
      }
    }

    for (var i = 0; i < children.length; i++) {
      final height = _heightFor(children[i]);
      if (height is FlexHeight) continue;

      final remainingHeight = availableHeight - usedHeight;
      if (remainingHeight <= 0) break;

      final childSize = children[i].layout(
        Constraints(maxWidth: constraints.maxWidth, maxHeight: remainingHeight),
      );

      usedHeight += childSize.height;
      maxChildWidth = max(maxChildWidth, childSize.width);
      _laidOutChildren[i] = true;
    }

    var remainingFlexHeight = max(0, availableHeight - usedHeight);
    var remainingFlexTotal = flexTotal;

    for (var i = 0; i < children.length; i++) {
      final height = _heightFor(children[i]);
      if (height is! FlexHeight) continue;
      if (remainingFlexHeight <= 0 || remainingFlexTotal <= 0) break;

      final allocatedHeight = remainingFlexTotal == height.flex
          ? remainingFlexHeight
          : max(
              0,
              (remainingFlexHeight * height.flex / remainingFlexTotal).floor(),
            );

      final childSize = children[i].layout(
        Constraints(maxWidth: constraints.maxWidth, maxHeight: allocatedHeight),
      );

      usedHeight += childSize.height;
      maxChildWidth = max(maxChildWidth, childSize.width);
      remainingFlexHeight = max(0, remainingFlexHeight - childSize.height);
      remainingFlexTotal -= height.flex;
      _laidOutChildren[i] = true;
    }

    final laidOutChildCount = _laidOutChildren.where((value) => value).length;
    final totalHeight = usedHeight + max(0, laidOutChildCount - 1) * gap;

    return Size(
      width: expandWidth ? constraints.maxWidth : maxChildWidth,
      height: totalHeight.clamp(0, constraints.maxHeight),
    );
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    var cursorY = y;
    var paintedCount = 0;
    final laidOutChildCount = _laidOutChildren.where((value) => value).length;

    for (var i = 0; i < children.length; i++) {
      if (!_laidOutChildren[i]) continue;

      final child = children[i];
      child.paint(canvas, x, cursorY);
      cursorY += child.size.height;
      paintedCount++;

      if (paintedCount < laidOutChildCount) {
        cursorY += gap;
      }
    }
  }

  Height? _heightFor(Widget child) {
    if (child case HeightConfigurable heightConfigurable) {
      return heightConfigurable.height;
    }

    return null;
  }
}
