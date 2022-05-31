/* A widget to display header text. */
import 'package:flutter/widgets.dart';

class ContentText extends StatelessWidget {
  final String text;
  final double marginTop;
  final double marginRight;
  final double marginLeft;
  final double marginBottom;
  ContentText(
      {required this.text,
        this.marginTop = 0,
        this.marginRight = 0,
        this.marginBottom = 0,
        this.marginLeft = 0});

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(fontSize: 14);
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