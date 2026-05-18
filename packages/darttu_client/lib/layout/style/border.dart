enum BorderStyle { single, rounded, doubleLine, heavy }

final class BorderChars {
  final String topLeft;
  final String topRight;
  final String bottomLeft;
  final String bottomRight;
  final String horizontal;
  final String vertical;
  final String leftJoin;
  final String rightJoin;

  const BorderChars({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.horizontal,
    required this.vertical,
    required this.leftJoin,
    required this.rightJoin,
  });

  factory BorderChars.fromStyle(BorderStyle style) {
    return switch (style) {
      BorderStyle.single => const BorderChars(
        topLeft: '┌',
        topRight: '┐',
        bottomLeft: '└',
        bottomRight: '┘',
        horizontal: '─',
        vertical: '│',
        leftJoin: '├',
        rightJoin: '┤',
      ),
      BorderStyle.rounded => const BorderChars(
        topLeft: '╭',
        topRight: '╮',
        bottomLeft: '╰',
        bottomRight: '╯',
        horizontal: '─',
        vertical: '│',
        leftJoin: '├',
        rightJoin: '┤',
      ),
      BorderStyle.doubleLine => const BorderChars(
        topLeft: '╔',
        topRight: '╗',
        bottomLeft: '╚',
        bottomRight: '╝',
        horizontal: '═',
        vertical: '║',
        leftJoin: '╠',
        rightJoin: '╣',
      ),
      BorderStyle.heavy => const BorderChars(
        topLeft: '┏',
        topRight: '┓',
        bottomLeft: '┗',
        bottomRight: '┛',
        horizontal: '━',
        vertical: '┃',
        leftJoin: '┣',
        rightJoin: '┫',
      ),
    };
  }
}
