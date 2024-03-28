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
                      '\n\n1. Open the Google Play Store app on your phone.\n\n2. Search for "Lucid Watch App" in the search bar at the top of the Play Store app.\n\n3. Tap the "Lucid Watch App" from the search results, tap "Install" next to it.',
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
