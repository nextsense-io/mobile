import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';

class RoundBackground extends StatelessWidget {

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;

  RoundBackground({required this.child, this.color = NextSenseColors.translucent, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: onPressed != null ? onPressed : () => {},
      elevation: 0,
      fillColor: color,
      child: child,
      shape: CircleBorder(),
    );
  }
}