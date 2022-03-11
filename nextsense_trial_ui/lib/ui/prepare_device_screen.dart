import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/config.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';

class PrepareDeviceScreen extends StatefulWidget {
  @override
  _PrepareDeviceScreenState createState() => _PrepareDeviceScreenState();
}

class _PrepareDeviceScreenState extends State<PrepareDeviceScreen> {

  @override
  Widget build(BuildContext context) {

    if (Config.useEmulatedBle) {
      Navigation.navigateToDeviceScan(
          context, /*replaceCurrent=*/true);
      return Container();
    }

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
                        Navigation.navigateToDeviceScan(
                            context, /*replaceCurrent=*/true);
                      },
                    )),
              ]),
        ),
      ),
    );
  }
}