import 'package:flutter/material.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';

class RemDetectionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const RemDetectionButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: ShapeDecoration(
          gradient: RadialGradient(
            center: Alignment(0.07, 0.78),
            radius: 0,
            colors: NextSenseColors.purpleGradiantColors,
          ),
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 2, color: NextSenseColors.royalPurple),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Set up REM detection for best results',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          ],
        ),
      ),
    );
  }
}
