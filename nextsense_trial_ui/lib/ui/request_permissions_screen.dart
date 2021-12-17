import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/device_scan_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class RequestPermissionsScreen extends StatefulWidget {
  @override
  _RequestPermissionsScreenState createState() => _RequestPermissionsScreenState();
}

class _RequestPermissionsScreenState extends State<RequestPermissionsScreen> {

  _requestPermissions() async {
    await Permission.locationWhenInUse.request();
    await Permission.ignoreBatteryOptimizations.request();
  }

  @override
  Widget build(BuildContext context) {
    _requestPermissions();
    return Scaffold(
      appBar: AppBar(
        title: Text("Request Permissions"),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text("Location permission is needed to connect to "
                      "Bluetooth, please accept the permission in the popup "
                      "after pressing continue.",
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
                        await Permission.locationWhenInUse.request();
                        if (await Permission.locationWhenInUse.isDenied) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return SimpleAlertDialog(title: 'Error', content:
                                  'Please try again and allow the location '
                                  'permission. It is not possible to connect '
                                  'to the NextSense device without it.');
                            },
                          );
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