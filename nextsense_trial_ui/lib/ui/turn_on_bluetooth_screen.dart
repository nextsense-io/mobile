import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/ui/components/background_decoration.dart';

class TurnOnBluetoothScreen extends HookWidget {

  static const String id = 'turn_on_bluetooth_screen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Turn Bluetooth On'),
      ),
      body: Container(
        decoration: baseBackgroundDecoration,
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text('Bluetooth is not enabled in your device, please '
                      'turn it on to be able to connect to your NextSense '
                      'device',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          fontFamily: 'Roboto')),
                ),
                Padding(
                    padding: EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      child: const Text('Open Bluetooth Settings'),
                      onPressed: () async {
                        // Check if Bluetooth is ON.
                        AppSettings.openBluetoothSettings();
                      },
                    )),
                Padding(
                    padding: EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      child: const Text('Continue'),
                      onPressed: () async {
                          // Ask the user to turn on Bluetooth.
                          Navigator.pop(context);
                      },
                    )),
              ]),
        ),
      ),
    );
  }
}