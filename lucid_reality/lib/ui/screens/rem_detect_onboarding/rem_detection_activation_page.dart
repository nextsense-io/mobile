import 'package:flutter/material.dart';

class REMDetectionActivationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          alignment: Alignment.center,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      'To activate REM detection, you must use the the Lucid Reality watch application.\n\n\nInstructions:',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                TextSpan(
                  text:
                      '\n\n1. Open the Apple Watch app on your iPhone.\n\n2. Tap the "My Watch" tab at the bottom of the screen.\n\n3. Scroll down to the "Available Apps" section. If you see Lucid Reality listed, tap "Install" next to it.',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
