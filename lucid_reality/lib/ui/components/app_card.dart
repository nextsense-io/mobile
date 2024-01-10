import 'package:flutter/material.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppCard(this.child, {super.key, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: padding,
        decoration: ShapeDecoration(
            color: NextSenseColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            )),
        child: child);
  }
}
