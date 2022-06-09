/* A widget to display header text. */
import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';

class EmphasizedText extends StatelessWidget {
  final String text;
  final Color color;
  final double marginTop;
  final double marginRight;
  final double marginLeft;
  final double marginBottom;
  EmphasizedText(
      {required this.text,
        this.color = NextSenseColors.darkBlue,
        this.marginTop = 0,
        this.marginRight = 0,
        this.marginBottom = 0,
        this.marginLeft = 0});

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic);
    return Container(
      margin: EdgeInsets.only(
        top: marginTop,
        right: marginRight,
        left: marginLeft,
        bottom: marginBottom,
      ),
      child: Text(text, style: headerStyle),
    );
  }
}