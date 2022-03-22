import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/components/background_decoration.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';

class PrepareDeviceScreen extends HookWidget {

  static const String id = 'prepare_device_screen';

  final Navigation _navigation = getIt<Navigation>();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Prepare Device'),
      ),
      body: Container(
        decoration: baseBackgroundDecoration,
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
                        _navigation.navigateToDeviceScan(replace: true);
                      },
                    )),
              ]),
        ),
      ),
    );
  }
}