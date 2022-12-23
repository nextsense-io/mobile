import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/earbud_configs.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/impedance_series.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/xenon_impedance_calculator.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/device_state_viewmodel.dart';
import 'package:wakelock/wakelock.dart';

enum EarFitRunState {
  NOT_STARTED,
  STARTING,
  RUNNING,
  STOPPING,
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

class EarFitScreenViewModel extends DeviceStateViewModel {

  static const int _impedanceSampleSize = 1024;
  // TODO(eric): This needs to be defined, and might be a combination of a high threshold (electrode
  //             reasonably in place) and the dynamic impedance stabilizing within a percentage.
  static const int _maxImpedanceThreshold = 8000000;
  static const int _minImpedanceThreshold = 10000;
  static const int _maxVariationPercent = 20;
  static const Duration _variationCheckDuration = Duration(seconds: 5);
  static const Duration _refreshInterval = Duration(milliseconds: 1000);
  static const List<int> _testStages = [1, 2];

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
  int _testStage = _testStages.last;
  Iterator<int> _testStageIterator = _testStages.iterator;
  bool _deviceConnected = true;
  ImpedanceSeries _impedanceSeries = ImpedanceSeries();

  EarFitRunState get earFitRunState => _earFitRunState;
  EarFitResultState get earFitResultState => _earFitResultState;
  Map<EarLocationName, EarLocationResultState> get earFitResults => _earFitResults;
  int get testStage => _testStage;
  bool get deviceConnected => _deviceConnected;

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
    _stopEarFitTest();
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
      case EarFitRunState.STARTING:
        // fallthrough
      case EarFitRunState.STOPPING:
        // Nothing to do, wait for the state to finish.
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
    _impedanceSeries.resetImpedanceData();
  }

  Future _startEarFitTest() async {
    _earFitRunState = EarFitRunState.STARTING;
    _initEarFitResults();
    notifyListeners();
    await _impedanceCalculator!.startADS1299AcImpedance();
    _screenRefreshTimer = new Timer.periodic(_refreshInterval, _runEarFitTest);
  }

  Future _stopEarFitTest() async {
    _earFitRunState = EarFitRunState.STOPPING;
    notifyListeners();
    _screenRefreshTimer?.cancel();
    await _impedanceCalculator?.stopCalculatingImpedance();
    _calculatingImpedance = false;
    _earFitRunState = EarFitRunState.FINISHED;
    notifyListeners();
    Wakelock.disable();
  }

  Future _runEarFitTest(Timer timer) async {
    if (_calculatingImpedance) {
      _logger.log(Level.INFO, 'Already calculating, returning');
      return;
    }
    _calculatingImpedance = true;
    ImpedanceData impedanceData = ImpedanceData(
        impedances: await _impedanceCalculator!.calculate1299AcImpedance(_earbudsConfig!),
        timestamp: DateTime.now());
    if (_earFitRunState != EarFitRunState.STARTING && _earFitRunState != EarFitRunState.RUNNING) {
      _calculatingImpedance = false;
      return;
    }
    _impedanceSeries.addImpedanceData(impedanceData);
    EarLocationResultState leftResult = EarLocationResultState.NO_RESULT;
    EarLocationResultState rightResult = EarLocationResultState.NO_RESULT;
    for (MapEntry<EarLocation, double> result in impedanceData.impedances.entries) {
      if (result.value < 0) {
        _earFitResults[result.key.name] = EarLocationResultState.NO_RESULT;
      } else {
        int variation = _impedanceSeries.getVariationAcrossTime(
            earLocation: result.key, time: _variationCheckDuration);
        if (variation < 0 || variation > _maxVariationPercent) {
          _earFitResults[result.key.name] = EarLocationResultState.POOR_FIT;
          _logger.log(Level.FINE, "Variation of ${_impedanceSeries.getVariationAcrossTime(
              earLocation: result.key, time: _variationCheckDuration)} is negative or above the "
              "threshold: $variation");
          continue;
        }
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

    if (_earFitRunState == EarFitRunState.STARTING &&
        _earFitResultState != EarFitResultState.NO_RESULTS) {
      _earFitRunState = EarFitRunState.RUNNING;
    }

    if (_earFitResultState == EarFitResultState.GOOD_FIT) {
      _testStage = _testStages.last;
    } else {
      if (!_testStageIterator.moveNext()) {
        _testStageIterator = _testStages.iterator;
        _testStageIterator.moveNext();
      }
      _testStage = _testStageIterator.current;
    }
    notifyListeners();
    _calculatingImpedance = false;
  }

  @override
  void onDeviceDisconnected() {
    _deviceConnected = false;
    _stopEarFitTest();
  }

  @override
  void onDeviceReconnected() {
    _deviceConnected = true;
    notifyListeners();
  }
}