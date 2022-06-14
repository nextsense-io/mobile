import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/components/clickable_zone.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';

class CancelButton extends StatelessWidget {

  final VoidCallback onPressed;

  CancelButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ClickableZone(child: Icon(Icons.cancel, size: 40, color: NextSenseColors.red),
        onTap: onPressed);
  }
}