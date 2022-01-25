import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

class TurnOnBluetoothScreen extends StatefulWidget {
  @override
  _TurnOnBluetoothScreenState createState() => _TurnOnBluetoothScreenState();
}

class _TurnOnBluetoothScreenState extends State<TurnOnBluetoothScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Turn Bluetooth On'),
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