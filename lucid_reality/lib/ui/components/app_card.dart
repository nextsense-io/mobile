import 'package:flutter/material.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color cardBackground;

  const AppCard(
    this.child, {
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.cardBackground = NextSenseColors.cardBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: ShapeDecoration(
        color: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: child,
    );
  }
}
