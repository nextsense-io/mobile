import 'package:flutter/material.dart';

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
          child: Text(
            'To use the REM detection feature, be sure to launch dream mode from the watch before you go to sleep.\nThis will ensure that your totem sounds play during REM, maximizing your chances for lucidity.',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}
