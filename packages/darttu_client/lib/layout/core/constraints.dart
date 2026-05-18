final class Constraints {
  final int maxWidth;
  final int maxHeight;

  const Constraints({required this.maxWidth, required this.maxHeight});

  Constraints shrink({int horizontal = 0, int vertical = 0}) {
    return Constraints(
      maxWidth: (maxWidth - horizontal).clamp(0, maxWidth),
      maxHeight: (maxHeight - vertical).clamp(0, maxHeight),
    );
  }
}
