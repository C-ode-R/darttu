sealed class Height {
  const Height();

  int resolve(int parentHeight);
}

abstract interface class HeightConfigurable {
  Height get height;
}

final class AutoHeight extends Height {
  const AutoHeight();

  @override
  int resolve(int parentHeight) => parentHeight;
}

final class FillHeight extends Height {
  const FillHeight();

  @override
  int resolve(int parentHeight) => parentHeight;
}

final class ExpandHeight extends Height {
  const ExpandHeight();

  @override
  int resolve(int parentHeight) => parentHeight;
}

final class FixedHeight extends Height {
  final int value;

  const FixedHeight(this.value);

  @override
  int resolve(int parentHeight) {
    return value.clamp(0, parentHeight);
  }
}

final class PercentHeight extends Height {
  final double ratio;

  const PercentHeight(this.ratio);

  @override
  int resolve(int parentHeight) {
    return (parentHeight * ratio).floor().clamp(0, parentHeight);
  }
}

final class FlexHeight extends Height {
  final int flex;

  const FlexHeight([this.flex = 1]) : assert(flex > 0);

  @override
  int resolve(int parentHeight) => parentHeight;
}
