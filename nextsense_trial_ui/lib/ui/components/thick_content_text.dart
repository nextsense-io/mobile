/* A widget to display header text. */
import 'package:flutter/material.dart';

class ThickContentText extends StatelessWidget {
  final String text;
  final Color color;
  final double marginTop;
  final double marginRight;
  final double marginLeft;
  final double marginBottom;
  ThickContentText(
      {required this.text,
        this.color = Colors.black,
        this.marginTop = 0,
        this.marginRight = 0,
        this.marginBottom = 0,
        this.marginLeft = 0});

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500);
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