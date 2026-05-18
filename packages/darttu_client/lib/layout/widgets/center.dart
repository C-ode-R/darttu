import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';
import '../style/height.dart';
import '../style/width.dart';

final class Center extends Widget
    implements WidthConfigurable, HeightConfigurable {
  @override
  final Width width;
  @override
  final Height height;
  final Widget child;

  Center({
    required this.child,
    this.width = const FillWidth(),
    this.height = const FillHeight(),
  });

  @override
  Size performLayout(Constraints constraints) {
    final childConstraints = Constraints(
      maxWidth: switch (width) {
        AutoWidth() => constraints.maxWidth,
        _ => width.resolve(constraints.maxWidth),
      },
      maxHeight: switch (height) {
        AutoHeight() => constraints.maxHeight,
        _ => height.resolve(constraints.maxHeight),
      },
    );

    final childSize = child.layout(childConstraints);

    final resolvedWidth = switch (width) {
      AutoWidth() => childSize.width,
      _ => childConstraints.maxWidth,
    };
    final resolvedHeight = switch (height) {
      AutoHeight() => childSize.height,
      _ => childConstraints.maxHeight,
    };

    return Size(
      width: resolvedWidth.clamp(0, constraints.maxWidth),
      height: resolvedHeight.clamp(0, constraints.maxHeight),
    );
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    final childX = x + ((size.width - child.size.width) ~/ 2);
    final childY = y + ((size.height - child.size.height) ~/ 2);

    child.paint(canvas, childX, childY);
  }
}
