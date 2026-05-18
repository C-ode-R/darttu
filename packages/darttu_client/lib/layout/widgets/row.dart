import 'dart:math';

import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';
import '../style/height.dart';
import '../style/width.dart';

final class Row extends Widget implements HeightConfigurable {
  final List<Widget> children;
  final int gap;
  @override
  final Height height;
  late List<bool> _laidOutChildren;

  Row({required this.children, this.gap = 0, this.height = const AutoHeight()});

  @override
  Size performLayout(Constraints constraints) {
    _laidOutChildren = List<bool>.filled(children.length, false);
    final rowMaxHeight = switch (height) {
      AutoHeight() => constraints.maxHeight,
      _ => height.resolve(constraints.maxHeight),
    };

    final availableWidth = max(
      0,
      constraints.maxWidth - (max(0, children.length - 1) * gap),
    );
    var usedWidth = 0;
    var maxHeight = 0;
    var flexTotal = 0;

    for (final child in children) {
      final width = _widthFor(child);
      if (width is FlexWidth) {
        flexTotal += width.flex;
      }
    }

    for (var i = 0; i < children.length; i++) {
      final width = _widthFor(children[i]);
      if (width is FlexWidth) continue;

      final remainingWidth = availableWidth - usedWidth;
      if (remainingWidth <= 0) break;

      final childSize = children[i].layout(
        Constraints(maxWidth: remainingWidth, maxHeight: rowMaxHeight),
      );

      usedWidth += childSize.width;
      maxHeight = max(maxHeight, childSize.height);
      _laidOutChildren[i] = true;
    }

    var remainingFlexWidth = max(0, availableWidth - usedWidth);
    var remainingFlexTotal = flexTotal;

    for (var i = 0; i < children.length; i++) {
      final width = _widthFor(children[i]);
      if (width is! FlexWidth) continue;
      if (remainingFlexWidth <= 0 || remainingFlexTotal <= 0) break;

      final allocatedWidth = remainingFlexTotal == width.flex
          ? remainingFlexWidth
          : max(
              0,
              (remainingFlexWidth * width.flex / remainingFlexTotal).floor(),
            );

      final childSize = children[i].layout(
        Constraints(maxWidth: allocatedWidth, maxHeight: rowMaxHeight),
      );

      usedWidth += childSize.width;
      maxHeight = max(maxHeight, childSize.height);
      remainingFlexWidth = max(0, remainingFlexWidth - childSize.width);
      remainingFlexTotal -= width.flex;
      _laidOutChildren[i] = true;
    }

    final laidOutChildCount = _laidOutChildren.where((value) => value).length;
    final totalWidth = usedWidth + max(0, laidOutChildCount - 1) * gap;

    final resolvedHeight = switch (height) {
      AutoHeight() => maxHeight,
      _ => rowMaxHeight,
    };

    return Size(
      width: totalWidth.clamp(0, constraints.maxWidth),
      height: resolvedHeight.clamp(0, constraints.maxHeight),
    );
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    var cursorX = x;
    var paintedCount = 0;
    final laidOutChildCount = _laidOutChildren.where((value) => value).length;

    for (var i = 0; i < children.length; i++) {
      if (!_laidOutChildren[i]) continue;

      final child = children[i];
      child.paint(canvas, cursorX, y);
      cursorX += child.size.width;
      paintedCount++;

      if (paintedCount < laidOutChildCount) {
        cursorX += gap;
      }
    }
  }

  Width? _widthFor(Widget child) {
    if (child case WidthConfigurable widthConfigurable) {
      return widthConfigurable.width;
    }

    return null;
  }
}
