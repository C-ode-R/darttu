final class EdgeInsets {
  final int left;
  final int right;
  final int top;
  final int bottom;

  const EdgeInsets({
    this.left = 0,
    this.right = 0,
    this.top = 0,
    this.bottom = 0,
  });

  const EdgeInsets.all(int value)
    : left = value,
      right = value,
      top = value,
      bottom = value;

  const EdgeInsets.symmetric({int horizontal = 0, int vertical = 0})
    : left = horizontal,
      right = horizontal,
      top = vertical,
      bottom = vertical;

  int get horizontal => left + right;
  int get vertical => top + bottom;
}
