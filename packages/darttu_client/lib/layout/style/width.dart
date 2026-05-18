sealed class Width {
  const Width();

  int resolve(int parentWidth);
}

abstract interface class WidthConfigurable {
  Width get width;
}

final class AutoWidth extends Width {
  const AutoWidth();

  @override
  int resolve(int parentWidth) => parentWidth;
}

final class FillWidth extends Width {
  const FillWidth();

  @override
  int resolve(int parentWidth) => parentWidth;
}

final class ExpandWidth extends Width {
  const ExpandWidth();

  @override
  int resolve(int parentWidth) => parentWidth;
}

final class FixedWidth extends Width {
  final int value;

  const FixedWidth(this.value);

  @override
  int resolve(int parentWidth) {
    return value.clamp(0, parentWidth);
  }
}

final class PercentWidth extends Width {
  final double ratio;

  const PercentWidth(this.ratio);

  @override
  int resolve(int parentWidth) {
    return (parentWidth * ratio).floor().clamp(0, parentWidth);
  }
}

final class FlexWidth extends Width {
  final int flex;

  const FlexWidth([this.flex = 1]) : assert(flex > 0);

  @override
  int resolve(int parentWidth) => parentWidth;
}
