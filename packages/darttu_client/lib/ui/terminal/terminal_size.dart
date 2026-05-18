import "dart:io";
import 'package:darttu_client/layout/core/size.dart';

Size getTerminalSize() {
  return Size(width: stdout.terminalColumns, height: stdout.terminalLines);
}
