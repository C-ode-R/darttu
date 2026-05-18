import 'canvas.dart';
import 'constraints.dart';
import 'widget.dart';

String renderWidget(Widget root, {required int width, required int height}) {
  final constraints = Constraints(maxWidth: width, maxHeight: height);

  root.layout(constraints);

  final canvas = Canvas(width: width, height: height);

  root.paint(canvas, 0, 0);

  return canvas.toString();
}
