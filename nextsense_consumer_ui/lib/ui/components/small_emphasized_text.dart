/* A widget to display small emphasized text. */
import 'package:flutter/material.dart';
import 'package:nextsense_consumer_ui/ui/nextsense_colors.dart';

class SmallEmphasizedText extends StatelessWidget {
  final String text;
  final Color color;
  final TextAlign textAlign;
  final double marginTop;
  final double marginRight;
  final double marginLeft;
  final double marginBottom;
  const SmallEmphasizedText(
      {super.key, required this.text,
        this.color = NextSenseColors.darkBlue,
        this.textAlign = TextAlign.start,
        this.marginTop = 0,
        this.marginRight = 0,
        this.marginBottom = 0,
        this.marginLeft = 0});

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic);
    return Container(
      margin: EdgeInsets.only(
        top: marginTop,
        right: marginRight,
        left: marginLeft,
        bottom: marginBottom,
      ),
      child: Text(text, style: headerStyle, textAlign: textAlign),
    );
  }
}