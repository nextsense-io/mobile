import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/earbud_configs.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/xenon_impedance_calculator.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';
import 'package:wakelock/wakelock.dart';

enum EarFitRunState {
  NOT_STARTED,
  RUNNING,
  FINISHED
}

enum EarFitResultState {
  NO_RESULTS,
  POOR_QUALITY_RIGHT,
  POOR_QUALITY_LEFT,
  POOR_QUALITY_BOTH,
  GOOD_FIT
}

enum EarLocationResultState {
  NO_RESULT,
  POOR_FIT,
  GOOD_FIT
}

class EarFitScreenViewModel extends ViewModel {

  static const int _impedanceSampleSize = 1024;
  // TODO(eric): This needs to be defined, and might be a combination of a high threshold (electrode
  //             reasonably in place) and the dynamic impedance stabilizing within a percentage.
  static const int _maxImpedanceThreshold = 8000000;
  static const int _minImpedanceThreshold = 10000;
  static const Duration _refreshInterval = Duration(milliseconds: 1000);

  final CustomLogPrinter _logger = CustomLogPrinter('EarFitScreenViewModel');
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final Navigation _navigation = getIt<Navigation>();

  EarFitRunState _earFitRunState = EarFitRunState.NOT_STARTED;
  EarFitResultState _earFitResultState = EarFitResultState.NO_RESULTS;
  XenonImpedanceCalculator? _impedanceCalculator;
  Map<String, dynamic>? _deviceSettings;
  EarbudsConfig? _earbudsConfig;
  Map<EarLocationName, EarLocationResultState> _earFitResults = {};
  bool _calculatingImpedance = false;
  Timer? _screenRefreshTimer;

  EarFitRunState get earFitRunState => _earFitRunState;
  EarFitResultState get earFitResultState => _earFitResultState;

  @override
  void init() async {
    _logger.log(Level.INFO, 'Initializing state.');
    super.init();

    Wakelock.enable();

    _earbudsConfig = EarbudsConfigs.getConfig(_studyManager.currentStudy!.getEarbudsConfig());
    _initEarFitResults();
    Device? connectedDevice = _deviceManager.getConnectedDevice();
    if (connectedDevice != null) {
      String macAddress = connectedDevice.macAddress;
      _deviceSettings = await NextsenseBase.getDeviceSettings(macAddress);
      _impedanceCalculator = new XenonImpedanceCalculator(
          samplesSize: _impedanceSampleSize, deviceSettingsValues: _deviceSettings!);
    }
  }

  @override
  void dispose() {
    Wakelock.disable();
    super.dispose();
  }

  Future buttonPress() async {
    switch (_earFitRunState) {
      case EarFitRunState.NOT_STARTED:
        _startEarFitTest();
        break;
      case EarFitRunState.RUNNING:
        if (_earFitResultState == EarFitResultState.GOOD_FIT) {
          _earFitRunState = EarFitRunState.FINISHED;
        } else {
          _earFitRunState = EarFitRunState.NOT_STARTED;
        }
        _stopEarFitTest();
        break;
      case EarFitRunState.FINISHED:
         if (_earFitResultState == EarFitResultState.GOOD_FIT) {
           _navigateToNextRoute();
         } else {
           _startEarFitTest();
         }
        break;
    }
  }

  Future stopAndExit() async {
    await _stopEarFitTest();
    _navigateToNextRoute();
  }

  void _navigateToNextRoute() {
    if (_navigation.canPop()) {
      _navigation.pop();
    } else {
      _navigation.navigateToNextRoute();
    }
  }

  void _initEarFitResults() {
    for (EarLocation earLocation in _earbudsConfig!.earLocations.values) {
      _earFitResults[earLocation.name] = EarLocationResultState.NO_RESULT;
    }
    _earFitResultState = EarFitResultState.NO_RESULTS;
  }

  void _startEarFitTest() {
    _earFitRunState = EarFitRunState.RUNNING;
    _initEarFitResults();
    notifyListeners();
    _impedanceCalculator!.startADS1299AcImpedance();
    _screenRefreshTimer = new Timer.periodic(_refreshInterval, _runEarFitTest);
  }

  Future _stopEarFitTest() async {
    _screenRefreshTimer?.cancel();
    await _impedanceCalculator?.stopCalculatingImpedance();
    _earFitRunState = EarFitRunState.FINISHED;
    _calculatingImpedance = false;
    notifyListeners();
    Wakelock.disable();
  }

  Future _runEarFitTest(Timer timer) async {
    if (_calculatingImpedance) {
      _logger.log(Level.INFO, 'Already calculating, returning');
      return;
    }
    _calculatingImpedance = true;
    Map<EarLocation, double> results =
        await _impedanceCalculator!.calculate1299AcImpedance(_earbudsConfig!);
    if (_earFitRunState != EarFitRunState.RUNNING) {
      _calculatingImpedance = false;
      return;
    }
    EarLocationResultState leftResult = EarLocationResultState.NO_RESULT;
    EarLocationResultState rightResult = EarLocationResultState.NO_RESULT;
    for (MapEntry<EarLocation, double> result in results.entries) {
      if (result.value < 0) {
        _earFitResults[result.key.name] = EarLocationResultState.NO_RESULT;
      } else {
        if (result.value > _minImpedanceThreshold && result.value < _maxImpedanceThreshold) {
          _earFitResults[result.key.name] = EarLocationResultState.GOOD_FIT;
        } else {
          _earFitResults[result.key.name] = EarLocationResultState.POOR_FIT;
        }
      }
    }

    // If there is impedance data results being calculated, set the RIGHT_HELIX to GOOD_FIT as good
    // as it is dependant on the rest of the electrodes.
    if (_earFitResults[EarLocationName.RIGHT_CANAL] != EarLocationResultState.NO_RESULT) {
      _earFitResults[EarLocationName.RIGHT_HELIX] = EarLocationResultState.GOOD_FIT;
    }

    if (_earFitResults[EarLocationName.LEFT_CANAL] == EarLocationResultState.NO_RESULT ||
        _earFitResults[EarLocationName.LEFT_HELIX] == EarLocationResultState.NO_RESULT) {
      leftResult = EarLocationResultState.NO_RESULT;
    } else if (_earFitResults[EarLocationName.LEFT_CANAL] == EarLocationResultState.POOR_FIT ||
        _earFitResults[EarLocationName.LEFT_HELIX] == EarLocationResultState.POOR_FIT) {
      leftResult = EarLocationResultState.POOR_FIT;
    } else {
      leftResult = EarLocationResultState.GOOD_FIT;
    }

    if (_earFitResults[EarLocationName.RIGHT_CANAL] == EarLocationResultState.NO_RESULT ||
        _earFitResults[EarLocationName.RIGHT_HELIX] == EarLocationResultState.NO_RESULT) {
      rightResult = EarLocationResultState.NO_RESULT;
    } else if (_earFitResults[EarLocationName.RIGHT_CANAL] == EarLocationResultState.POOR_FIT ||
        _earFitResults[EarLocationName.RIGHT_HELIX] == EarLocationResultState.POOR_FIT) {
      rightResult = EarLocationResultState.POOR_FIT;
    } else {
      rightResult = EarLocationResultState.GOOD_FIT;
    }

    if (leftResult == EarLocationResultState.NO_RESULT ||
        rightResult == EarLocationResultState.NO_RESULT) {
      _earFitResultState = EarFitResultState.NO_RESULTS;
    } else if (leftResult == EarLocationResultState.POOR_FIT &&
        rightResult == EarLocationResultState.POOR_FIT) {
      _earFitResultState = EarFitResultState.POOR_QUALITY_BOTH;
    } else if (leftResult == EarLocationResultState.GOOD_FIT &&
        rightResult == EarLocationResultState.GOOD_FIT) {
      _earFitResultState = EarFitResultState.GOOD_FIT;
      _stopEarFitTest();
    } else if (leftResult == EarLocationResultState.POOR_FIT) {
      _earFitResultState = EarFitResultState.POOR_QUALITY_LEFT;
    } else {
      _earFitResultState = EarFitResultState.POOR_QUALITY_RIGHT;
    }

    notifyListeners();
    _calculatingImpedance = false;
  }
}