import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/request_permissions_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class PrepareDeviceScreen extends StatefulWidget {
  @override
  _PrepareDeviceScreenState createState() => _PrepareDeviceScreenState();
}

class _PrepareDeviceScreenState extends State<PrepareDeviceScreen> {

  _requestPermissions() async {
    await Permission.locationWhenInUse.request();
    await Permission.ignoreBatteryOptimizations.request();
  }

  @override
  Widget build(BuildContext context) {
    _requestPermissions();
    return Scaffold(
      appBar: AppBar(
        title: Text("Prepare Device"),
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
                  child: Text("Move the slider to the ON position on your device",
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
                          // Navigate to device scan screen.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RequestPermissionsScreen()),
                          );
                      },
                    )),
              ]),
        ),
      ),
    );
  }
}