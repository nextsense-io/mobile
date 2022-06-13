import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/components/clickable_zone.dart';
import 'package:nextsense_trial_ui/ui/components/rounded_background.dart';

// Button with emphasized colors that should grab the attention as a main next action.
class EmphasizedButton extends StatelessWidget {

  final Widget text;
  final Function onTap;
  final bool enabled;

  EmphasizedButton({required this.text, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return ClickableZone(
      onTap: enabled ? onTap : () => {},
        child: Opacity(opacity: enabled ? 1.0 : 0.5, child: RoundedBackground(
            child: text,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[
                Color(0xffDB565B),
                Color(0xff984DF1),
              ],
            )
        )));
  }
}