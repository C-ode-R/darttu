final class Offset {
  final int x;
  final int y;

  const Offset({required this.x, required this.y});

  Offset translate(int dx, int dy) {
    return Offset(x: x + dx, y: y + dy);
  }
}
