import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';

class WaitWidget extends StatelessWidget {
  final String message;
  final bool textVisible;

  const WaitWidget({required this.message, this.textVisible = true});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            visible: textVisible,
            child: MediumText(text: message, textAlign: TextAlign.center)),
          SizedBox(
            height: 20,
          ),
          Container(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              color: NextSenseColors.purple,
            ),
          ),
        ],
      ),
    );
  }
}