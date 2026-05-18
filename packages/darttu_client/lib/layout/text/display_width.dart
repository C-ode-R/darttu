int displayWidth(String text) {
  var width = 0;

  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    width += isWideChar(char) ? 2 : 1;
  }

  return width;
}

bool isWideChar(String char) {
  final code = char.runes.first;

  if (code >= 0x1100 && code <= 0x11FF) return true;
  if (code >= 0x3130 && code <= 0x318F) return true;
  if (code >= 0x3000 && code <= 0x303F) return true;
  if (code >= 0x3040 && code <= 0x309F) return true;
  if (code >= 0x30A0 && code <= 0x30FF) return true;
  if (code >= 0x4E00 && code <= 0x9FFF) return true;
  if (code >= 0xAC00 && code <= 0xD7AF) return true;
  if (code >= 0xFF00 && code <= 0xFFEF) return true;

  return false;
}
