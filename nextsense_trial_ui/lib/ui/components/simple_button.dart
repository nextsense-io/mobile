import 'package:flutter/material.dart';
import 'package:flutter_common/ui/components/clickable_zone.dart';
import 'package:nextsense_trial_ui/ui/components/rounded_background.dart';

// Button with muted colors that should not grab the attention too much.
class SimpleButton extends StatelessWidget {

  final Widget text;
  final Border? border;
  final Function onTap;
  final bool? fullWidth;

  SimpleButton({required this.text, required this.onTap, this.border, this.fullWidth});

  @override
  Widget build(BuildContext context) {
    return ClickableZone(
        onTap: onTap,
        child: RoundedBackground(
            border: border,
            child: text,
            fullWidth: fullWidth ?? false,
        ));
  }
}