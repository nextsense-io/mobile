import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_common/domain/earbuds_config.dart';
import 'package:flutter_common/managers/device_manager.dart';
import 'package:flutter_common/managers/xenon_impedance_calculator.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:flutter_common/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:flutter_common/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum ImpedanceRunState {
  STOPPED,
  STARTING,
  STARTED
}

class ImpedanceCalculationScreen extends StatefulWidget {
  static const String id = 'impedance_calculation_screen';

  @override
  _ImpedanceCalculationScreenState createState() => _ImpedanceCalculationScreenState();
}

class _ImpedanceCalculationScreenState extends State<ImpedanceCalculationScreen> {
  static const Duration _refreshInterval = Duration(milliseconds: 1000);
  static const int _impedanceSampleSize = 1024;

  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('ImpedanceCalculationScreen');
  ImpedanceRunState _impedanceRunState = ImpedanceRunState.STOPPED;
  bool _calculatingImpedance = false;
  XenonImpedanceCalculator? _impedanceCalculator;
  Map<String, dynamic>? _deviceSettings;
  Timer? _screenRefreshTimer;
  String _impedanceResult = 'Waiting for results';

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
      _impedanceCalculator = new XenonImpedanceCalculator(
          samplesSize: _impedanceSampleSize, deviceSettingsValues: _deviceSettings!);
    }
  }

  String _spaceInt(int integer) {
    String intString = integer.toString();
    String spacedIntString = '';
    while (intString.length > 3) {
      spacedIntString = intString.substring(max(0, intString.length - 3), intString.length) +
          ' ' + spacedIntString;
      intString = intString.substring(0, max(1, intString.length - 3));
    }
    return intString + ' ' + spacedIntString.trim();
  }

  _calculateImpedance(Timer timer) {
    _logger.log(Level.INFO, 'starting impedance calculation');
    if (_calculatingImpedance) {
      _logger.log(Level.INFO, 'already calculating, returning');
      return;
    }
    _calculatingImpedance = true;
    EarbudsConfig earbudsConfig = EarbudsConfigs.getConfig(
        _studyManager.currentStudy!.getEarbudsConfig());
    _impedanceCalculator?.calculate1299AcImpedance(earbudsConfig).then((impedanceData) {
      String resultsText = '';
      for (MapEntry<EarLocation, double> mapEntry in impedanceData.entries) {
        String valueText = '';
        if (mapEntry.value == XenonImpedanceCalculator.impedanceNotEnoughData) {
          valueText = 'Not enough data';
        } else if (mapEntry.value == XenonImpedanceCalculator.impedanceFlatSignal) {
          valueText = 'Saturated or flat signal';
        } else {
          valueText = _spaceInt(mapEntry.value.round());
        }
        resultsText += '${mapEntry.key.getDisplayName()}: $valueText\n\n';
      }
      _logger.log(Level.INFO, resultsText);
      if (mounted) {
        setState(() {
          _impedanceResult = resultsText;
        });
      }
      _logger.log(Level.INFO, 'updated impedance result');
      _calculatingImpedance = false;
    });
  }

  @override
  dispose() async {
    _stopCalculating();
    super.dispose();
  }

  Future _stopCalculating() async {
    _screenRefreshTimer?.cancel();
    await _impedanceCalculator?.stopCalculatingImpedance();
    await WakelockPlus.disable();
    _impedanceRunState = ImpedanceRunState.STOPPED;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    String buttonText;
    switch (_impedanceRunState) {
      case ImpedanceRunState.STOPPED:
        buttonText = 'Start';
        break;
      case ImpedanceRunState.STARTING:
        buttonText = 'Start';
        break;
      case ImpedanceRunState.STARTED:
        buttonText = 'Stop';
        break;
    }
    return PageScaffold(
      child: Container(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10.0),
              child: MediumText(
                text: 'Press start once the earbuds are inserted in your ears and stay still '
                    'while checking if there is a good contact. It will take a few seconds to get '
                    'values.',
                color: NextSenseColors.darkBlue,
              ),
            ),
            SizedBox(height: 10),
            MediumText(text: _impedanceResult, color: NextSenseColors.darkBlue),
            SizedBox(height: 10),
            Padding(
                padding: EdgeInsets.all(10.0),
                child: SimpleButton(
                  text: MediumText(text: buttonText, color: NextSenseColors.purple),
                  onTap: () async {
                    if (_impedanceRunState == ImpedanceRunState.STOPPED) {
                      if (!_deviceManager.deviceIsReady) {
                        await showDialog(
                            context: context,
                            builder: (_) => SimpleAlertDialog(
                                title: 'Device is not connected',
                                content: 'Use the Connect button to connect with a device first.'));
                        return;
                      }
                      setState(() {
                        _impedanceRunState = ImpedanceRunState.STARTING;
                      });
                      bool started = await _impedanceCalculator!.startADS1299AcImpedance();
                      if (!started) {
                        await showDialog(
                            context: context,
                            builder: (_) => SimpleAlertDialog(
                                title: 'Could not start impedance calculation',
                                content: 'Please try again. If you just stopped a session it could '
                                    'take a few seconds for the device to be ready.'));
                        setState(() {
                          _impedanceRunState = ImpedanceRunState.STOPPED;
                        });
                        return;
                      }
                      WakelockPlus.enable();
                      _screenRefreshTimer =
                          new Timer.periodic(_refreshInterval, _calculateImpedance);
                      setState(() {
                        _impedanceRunState = ImpedanceRunState.STARTED;
                      });
                    } else if (_impedanceRunState == ImpedanceRunState.STARTED) {
                      _stopCalculating();
                    }
                  },
                )),
          ]),
        ),
      ),
    );
  }
}
