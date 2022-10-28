import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';

class RoundBackground extends StatelessWidget {

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final double elevation;
  final EdgeInsetsGeometry padding;
  final double width;
  final double height;

  RoundBackground({required this.child, this.color = NextSenseColors.translucent,
    this.elevation = 0, this.onPressed, this.width = 40, this.height = 40,
    this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: height, child: Card( // with Card
      child: child,
      elevation: 3.0,
      shape: CircleBorder(),
      margin: padding,
      clipBehavior: Clip.antiAlias,
    ));
  }
}