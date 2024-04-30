import 'package:flutter/material.dart';
import 'package:lucid_reality/utils/text_theme.dart';

class ToUseTheRemDetectionFeaturePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          alignment: Alignment.center,
          child: Text.rich(
            style: Theme.of(context).textTheme.labelLarge,
            TextSpan(
              children: [
                TextSpan(
                  text:
                      'To use the REM detection feature, be sure to launch dream mode from the watch before you go to sleep.\nThis will ensure that your totem sounds play during REM, maximizing your chances for lucidity.',
                ),
                TextSpan(
                  text: '\n\n\n',
                ),
                TextSpan(
                  text: 'Note that this feature will not work if your device is in silent mode',
                  style: Theme.of(context).textTheme.labelLargeWithFontWeight600,
                ),
                TextSpan(
                  text: ' or if notifications from Lucid Reality are silenced.',
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
