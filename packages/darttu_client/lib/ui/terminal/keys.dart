final class Keys {
  static const enterCR = '\r';
  static const enterLF = '\n';
  static const backspace = '\x7F';
  static const escape = '\x1B';

  static const arrowUp = '\x1B[A';
  static const arrowDown = '\x1B[B';
  static const arrowRight = '\x1B[C';
  static const arrowLeft = '\x1B[D';

  static const ctrlC = '\x03';

  static bool isEnter(String input) {
    return input == enterCR || input == enterLF;
  }

  static bool isBackspace(String input) {
    return input == backspace || input == '\b';
  }

  static bool isPrintable(String input) {
    if (input.isEmpty) return false;
    if (input.startsWith('\x1B')) return false;
    if (input == '\t') return false;
    if (isEnter(input)) return false;
    if (isBackspace(input)) return false;
    if (input == ctrlC) return false;

    return true;
  }
}
