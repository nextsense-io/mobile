import 'package:flutter/material.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/ui/device_scan_screen.dart';
import 'package:nextsense_trial_ui/ui/turn_on_bluetooth_screen.dart';

class Navigation {

  static Future navigateToDeviceScan(
      BuildContext context, bool replaceCurrent) async {
    // Check if Bluetooth is ON.
    if (!await NextsenseBase.isBluetoothEnabled()) {
      // Ask the user to turn on Bluetooth.
      // Navigate to device scan screen.
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TurnOnBluetoothScreen()),
      );
      if (await NextsenseBase.isBluetoothEnabled()) {
        if (replaceCurrent) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DeviceScanScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DeviceScanScreen()),
          );
        }
      }
    } else {
      // Navigate to device scan screen.
      if (replaceCurrent) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DeviceScanScreen()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DeviceScanScreen()),
        );
      }
    }
  }
}
