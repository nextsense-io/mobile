import 'package:flutter/material.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';

class AppCircularProgressBar extends StatelessWidget {
  final double value;
  final String text;
  final Size size;

  AppCircularProgressBar({super.key, required this.size, this.value = 0, this.text = ''});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        SizedBox.fromSize(
          size: this.size,
          child: CircularProgressIndicator(
            value: value,
            backgroundColor: NextSenseColors.royalPurple,
            valueColor: AlwaysStoppedAnimation<Color>(NextSenseColors.translucent),
            semanticsLabel: 'Circular progress indicator',
          ),
        ),
        Text(text, style: Theme.of(context).textTheme.bodySmall)
      ],
    );
  }
}
