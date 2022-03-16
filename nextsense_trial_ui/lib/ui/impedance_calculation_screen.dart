import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gson/values.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/xenon_impedance_calculator.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class ImpedanceCalculationScreen extends StatefulWidget {
  static const String id = 'impedance_calculation_screen';

  @override
  _ImpedanceCalculationScreenState createState() =>
      _ImpedanceCalculationScreenState();
}

class _ImpedanceCalculationScreenState extends
    State<ImpedanceCalculationScreen> {

  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final CustomLogPrinter _logger =
      CustomLogPrinter('ImpedanceCalculationScreen');
  XenonImpedanceCalculator? _impedanceCalculator;
  HashMap<int, double>? _impedanceResults;
  Map<String, dynamic>? _deviceSettings;

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
      _deviceSettings = await NextsenseBase.getDeviceSettings(macAddress);
      _impedanceCalculator = new XenonImpedanceCalculator(samplesSize: 250,
          deviceSettings: _deviceSettings!);
    }
  }

  Future _calculateImpedance() async {
    _impedanceResults = await _impedanceCalculator
        ?.calculateAllChannelsImpedance(ImpedanceMode.ON_1299_AC);
    if (_impedanceResults != null) {
      String resultsText = '';
      for (Integer channel in _deviceSettings![
          describeEnum(DeviceSettingsFields.enabledChannels)]) {
        resultsText += 'Channel ${channel.toSimple()}: ' +
            _impedanceResults![channel.toSimple()]!.round().toString() + '\n\n';
      }
      _logger.log(Level.INFO, resultsText);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleAlertDialog(
              title: 'Impedance Results',
              content: resultsText);
        },
      );
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
                        _calculateImpedance();
                      },
                    )),
              ]),
        ),
      ),
    );
  }
}