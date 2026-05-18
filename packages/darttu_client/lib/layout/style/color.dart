enum TerminalColor {
  black,
  red,
  green,
  yellow,
  blue,
  magenta,
  cyan,
  white,
  brightBlack,
  brightRed,
  brightGreen,
  brightYellow,
  brightBlue,
  brightMagenta,
  brightCyan,
  brightWhite,
}

final class TerminalColors {
  const TerminalColors._();

  static String foregroundCode(TerminalColor color) {
    return switch (color) {
      TerminalColor.black => '30',
      TerminalColor.red => '31',
      TerminalColor.green => '32',
      TerminalColor.yellow => '33',
      TerminalColor.blue => '34',
      TerminalColor.magenta => '35',
      TerminalColor.cyan => '36',
      TerminalColor.white => '37',
      TerminalColor.brightBlack => '90',
      TerminalColor.brightRed => '91',
      TerminalColor.brightGreen => '92',
      TerminalColor.brightYellow => '93',
      TerminalColor.brightBlue => '94',
      TerminalColor.brightMagenta => '95',
      TerminalColor.brightCyan => '96',
      TerminalColor.brightWhite => '97',
    };
  }

  static String backgroundCode(TerminalColor color) {
    return switch (color) {
      TerminalColor.black => '40',
      TerminalColor.red => '41',
      TerminalColor.green => '42',
      TerminalColor.yellow => '43',
      TerminalColor.blue => '44',
      TerminalColor.magenta => '45',
      TerminalColor.cyan => '46',
      TerminalColor.white => '47',
      TerminalColor.brightBlack => '100',
      TerminalColor.brightRed => '101',
      TerminalColor.brightGreen => '102',
      TerminalColor.brightYellow => '103',
      TerminalColor.brightBlue => '104',
      TerminalColor.brightMagenta => '105',
      TerminalColor.brightCyan => '106',
      TerminalColor.brightWhite => '107',
    };
  }
}
