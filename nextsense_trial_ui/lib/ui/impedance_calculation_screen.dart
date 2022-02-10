import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/xenon_impedance_calculator.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class ImpedanceCalculationScreen extends StatefulWidget {
  @override
  _ImpedanceCalculationScreenState createState() =>
      _ImpedanceCalculationScreenState();
}

class _ImpedanceCalculationScreenState extends
    State<ImpedanceCalculationScreen> {

  final DeviceManager _deviceManager = GetIt.instance.get<DeviceManager>();
  final CustomLogPrinter _logger =
      CustomLogPrinter('ImpedanceCalculationScreen');
  XenonImpedanceCalculator? _impedanceCalculator;
  HashMap<int, double>? _impedanceResults;

  @override
  void initState() {
    _logger.log(Level.INFO, 'Initializing state.');
    super.initState();
    _init();
  }

  Future _init() async {
    Device? connectedDevice = _deviceManager.getConnectedDevice();
    if (connectedDevice != null) {
      String macAddress = connectedDevice.macAddress;
      _impedanceCalculator = new XenonImpedanceCalculator(samplesSize: 250,
          deviceSettings: await NextsenseBase.getDeviceSettings(macAddress));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check earbuds seating'),
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
                  child: Text('Press continue once the earbuds are inserted '
                      'in your ears and stay still while checking if there is '
                      'a good contact. It will take around 30 seconds.',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          fontFamily: 'Roboto')),
                ),
                Padding(
                    padding: EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      child: const Text('Continue'),
                      onPressed: () async {
                        _impedanceResults = await _impedanceCalculator
                              ?.calculateAllChannelsImpedance();
                        if (_impedanceResults != null) {
                          _logger.log(Level.INFO, 'Impedance 1: ' +
                              _impedanceResults![1].toString());
                          _logger.log(Level.INFO, 'Impedance 3: ' +
                              _impedanceResults![3].toString());
                          _logger.log(Level.INFO, 'Impedance 6: ' +
                              _impedanceResults![6].toString());
                          _logger.log(Level.INFO, 'Impedance 7: ' +
                              _impedanceResults![7].toString());
                          _logger.log(Level.INFO, 'Impedance 8: ' +
                              _impedanceResults![8].toString());
                        }
                      },
                    )),
              ]),
        ),
      ),
    );
  }
}