/* A widget to display header text. */
import 'package:flutter/widgets.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';

class BigText extends StatelessWidget {
  final String text;
  final double marginTop;
  final double marginRight;
  final double marginLeft;
  final double marginBottom;
  BigText(
      {required this.text,
        this.marginTop = 0,
        this.marginRight = 0,
        this.marginBottom = 0,
        this.marginLeft = 0});

  @override
  Widget build(BuildContext context) {
    final headerStyle =
    TextStyle(fontWeight: FontWeight.w400, fontSize: 48, color: NextSenseColors.purple);
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