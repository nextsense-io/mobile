import 'package:flutter/widgets.dart';

class ScrollableColumn extends StatelessWidget {
  const ScrollableColumn(
      {Key? key,
      required this.children,
      this.crossAxisAlignment = CrossAxisAlignment.center,
      this.textDirection,
      this.mainAxisAlignment = MainAxisAlignment.start,
      this.mainAxisSize = MainAxisSize.max,
      this.verticalDirection = VerticalDirection.down,
      this.textBaseline})
      : super(key: key);
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          // Constrained box stops the column from getting too small, forcing it to be at least as tall as it's parent
          constraints:
              BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
          // Intrinsic height stops the column from expanding forever when it's height becomes unbounded
          // It will always use the full height of the parent, or the natural size of the children, whichever is greater.
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: crossAxisAlignment,
              textDirection: textDirection,
              mainAxisAlignment: mainAxisAlignment,
              mainAxisSize: mainAxisSize,
              verticalDirection: verticalDirection,
              textBaseline: textBaseline,
              children: children,
            ),
          ),
        ),
      );
    });
  }
}
