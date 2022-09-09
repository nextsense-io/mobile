import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';

class TurnOnBluetoothScreen extends HookWidget {
  static const String id = 'turn_on_bluetooth_screen';

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      showBackButton: Navigator.of(context).canPop(),
      showProfileButton: false,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Padding(
            padding: EdgeInsets.all(10.0),
            child: MediumText(
                text: 'Bluetooth is not enabled in your device, please turn it '
                    'on to be able to connect to your NextSense device',
                color: NextSenseColors.darkBlue),
          ),
          Padding(
              padding: EdgeInsets.all(10.0),
              child: SimpleButton(
                text: MediumText(text: 'Open Bluetooth Settings', color: NextSenseColors.darkBlue),
                onTap: () async {
                  // Check if Bluetooth is ON.
                  AppSettings.openBluetoothSettings();
                },
              )),
          Padding(
              padding: EdgeInsets.all(10.0),
              child: SimpleButton(
                text: MediumText(text: 'Continue', color: NextSenseColors.darkBlue),
                onTap: () async {
                  // Ask the user to turn on Bluetooth.
                  Navigator.pop(context);
                },
              )),
        ]),
      ),
    );
  }
}
