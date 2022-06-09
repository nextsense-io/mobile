import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/components/clickable_zone.dart';
import 'package:nextsense_trial_ui/ui/components/rounded_background.dart';

// Button with muted colors that should not grab the attention too much.
class SimpleButton extends StatelessWidget {

  final Widget text;
  final Function onTap;

  SimpleButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClickableZone(
        onTap: onTap,
        child: RoundedBackground(
            child: text,
        ));
  }
}