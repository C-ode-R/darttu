import '../style/text_align.dart';
import 'display_width.dart';

String truncateDisplay(String text, int maxWidth) {
  if (maxWidth <= 0) return '';

  final buffer = StringBuffer();
  var currentWidth = 0;

  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    final charWidth = isWideChar(char) ? 2 : 1;

    if (currentWidth + charWidth > maxWidth) break;

    buffer.write(char);
    currentWidth += charWidth;
  }

  return buffer.toString();
}

String alignText(String text, int width, {TextAlign align = TextAlign.left}) {
  final clipped = truncateDisplay(text, width);
  final textWidth = displayWidth(clipped);

  if (textWidth >= width) return clipped;

  final space = width - textWidth;

  return switch (align) {
    TextAlign.left => '$clipped${' ' * space}',
    TextAlign.right => '${' ' * space}$clipped',
    TextAlign.center =>
      '${' ' * (space ~/ 2)}$clipped${' ' * (space - space ~/ 2)}',
  };
}
