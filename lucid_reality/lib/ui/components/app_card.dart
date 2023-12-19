import 'package:flutter/material.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';

class AppCard extends StatelessWidget {

  final Widget child;

  AppCard(this.child, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
            color: NextSenseColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            )),
        child: child);
  }
}