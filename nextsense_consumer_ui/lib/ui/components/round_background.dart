import 'package:flutter/material.dart';
import 'package:nextsense_consumer_ui/ui/nextsense_colors.dart';

class RoundBackground extends StatelessWidget {

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final double elevation;
  final EdgeInsetsGeometry padding;
  final double width;
  final double height;

  const RoundBackground({super.key, required this.child, this.color = NextSenseColors.translucent,
    this.elevation = 0, this.onPressed, this.width = 40, this.height = 40,
    this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height, child: Card( // with Card
      elevation: 3.0,
      shape: const CircleBorder(),
      margin: padding,
      clipBehavior: Clip.antiAlias, // with Card
      child: child,
    ));
  }
}