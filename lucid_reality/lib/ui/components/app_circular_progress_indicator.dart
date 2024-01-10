import 'package:flutter/material.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';

class AppCircleProgressIndicator extends StatelessWidget {
  const AppCircleProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(NextSenseColors.royalPurple),
      ),
    );
  }
}
