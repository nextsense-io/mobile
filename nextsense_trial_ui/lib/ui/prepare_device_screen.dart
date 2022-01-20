import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/ui/device_scan_screen.dart';
import 'package:nextsense_trial_ui/ui/turn_on_bluetooth_screen.dart';

class PrepareDeviceScreen extends StatefulWidget {
  @override
  _PrepareDeviceScreenState createState() => _PrepareDeviceScreenState();
}

class _PrepareDeviceScreenState extends State<PrepareDeviceScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prepare Device'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text('Move the slider to the ON position on your device',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          fontFamily: 'Roboto')),
                ),
                Padding(
                    padding: EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      child: const Text('Continue'),
                      onPressed: () async {
                        // Check if Bluetooth is ON.
                        if (!await NextsenseBase.isBluetoothEnabled()) {
                          // Ask the user to turn on Bluetooth.
                          // Navigate to device scan screen.
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TurnOnBluetoothScreen()),
                          );
                          if (await NextsenseBase.isBluetoothEnabled()) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DeviceScanScreen()),
                            );
                          }
                        } else {
                          // Navigate to device scan screen.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DeviceScanScreen()),
                          );
                        }
                      },
                    )),
              ]),
        ),
      ),
    );
  }
}