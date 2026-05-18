import '../core/canvas.dart';
import '../core/constraints.dart';
import '../core/size.dart';
import '../core/widget.dart';
import '../style/color.dart';

final class ProgressBar extends Widget {
  final double progress;
  final int? width;
  final bool showPercentage;
  final String filledChar;
  final String emptyChar;
  final TerminalColor? foregroundColor;
  final TerminalColor? backgroundColor;
  final TerminalColor? trackForegroundColor;
  final TerminalColor? trackBackgroundColor;

  ProgressBar({
    required this.progress,
    this.width,
    this.showPercentage = false,
    this.filledChar = '█',
    this.emptyChar = '░',
    this.foregroundColor,
    this.backgroundColor,
    this.trackForegroundColor,
    this.trackBackgroundColor,
  });

  @override
  Size performLayout(Constraints constraints) {
    final requestedWidth = width ?? constraints.maxWidth;
    final resolvedWidth = requestedWidth < 0
        ? 0
        : (requestedWidth > constraints.maxWidth
              ? constraints.maxWidth
              : requestedWidth);
    return Size(
      width: resolvedWidth,
      height: constraints.maxHeight <= 0 ? 0 : 1,
    );
  }

  @override
  void paint(Canvas canvas, int x, int y) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final normalizedProgress = progress.clamp(0.0, 1.0);
    final suffix = showPercentage
        ? ' ${(normalizedProgress * 100).round()}%'
        : '';
    final suffixWidth = suffix.length;
    final barWidth = size.width - suffixWidth < 0
        ? 0
        : size.width - suffixWidth;

    if (barWidth > 0) {
      final rawFilledWidth = (barWidth * normalizedProgress).round();
      final filledWidth = rawFilledWidth < 0
          ? 0
          : (rawFilledWidth > barWidth ? barWidth : rawFilledWidth);
      final emptyWidth = barWidth - filledWidth;

      if (filledWidth > 0) {
        canvas.write(
          x,
          y,
          filledChar * filledWidth,
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
        );
      }

      if (emptyWidth > 0) {
        canvas.write(
          x + filledWidth,
          y,
          emptyChar * emptyWidth,
          foregroundColor: trackForegroundColor,
          backgroundColor: trackBackgroundColor,
        );
      }
    }

    if (suffix.isNotEmpty && suffixWidth <= size.width) {
      canvas.write(
        x + size.width - suffixWidth,
        y,
        suffix,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
      );
    }
  }
}
