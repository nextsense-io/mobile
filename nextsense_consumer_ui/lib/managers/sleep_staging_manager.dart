import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_common/domain/earbuds_config.dart';
import 'package:flutter_common/managers/device_manager.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/managers/session_manager.dart';

enum SleepCalculationState {
  calculating,  // Currently calculating sleep staging results.
  waiting  // Currently not calculating sleep staging results.
}

enum SleepStagingState {
  notStarted,  // Not started sleep staging.
  started,  // Started sleep staging, ongoing calculations at regular intervals.
  stopping,  // Stopping sleep staging, finishing the last calculation then will be `complete`.
  complete  // Sleep staging results complete.
}

class SleepStagingManager extends ChangeNotifier {
  static const String _stagingLabelsKey = "0";
  static const String _confidencesKey = "1";
  // 30 seconds per epoch, current model runs with a maximum number of 21 epochs.
  static const Duration _singleSleepEpoch = Duration(seconds: 30);
  static const Duration _calculationEpoch = Duration(seconds: 21 * 30);
  static const Duration _calculationCheckInterval = _singleSleepEpoch;

  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final SessionManager _sessionManager = getIt<SessionManager>();
  final _logger = Logger('SleepStagingManager');

  // Interval between sleep staging calculations.
  Duration? _sleepStagingCalculationInterval;
  DateTime? _sleepStartTime;
  Duration _calculatedDuration = Duration.zero;
  Timer? _checkIfNeedToCalculateTimer;

  SleepCalculationState _sleepCalculationState = SleepCalculationState.waiting;
  SleepStagingState _sleepStagingState = SleepStagingState.notStarted;
  List<dynamic> _sleepStagingLabels = [];
  List<dynamic> _sleepStagingConfidences = [];

  SleepStagingState get sleepStagingState => _sleepStagingState;
  SleepCalculationState get sleepCalculationState => _sleepCalculationState;
  List<dynamic> get sleepStagingLabels => _sleepStagingLabels;
  List<dynamic> get sleepStagingConfidences => _sleepStagingConfidences;

  void startSleepStaging({Duration calculationInterval = const Duration(minutes: 5)}) {
    clearSleepStaging();
    _sleepStartTime = DateTime.now();
    _sleepStagingCalculationInterval = calculationInterval;
    _sleepCalculationState = SleepCalculationState.waiting;
    _sleepStagingState = SleepStagingState.started;
    _checkIfNeedToCalculateTimer = Timer.periodic(
      _calculationCheckInterval, (timer) async {
      _checkIfNeedToCalculate();
    });
  }

  void stopSleepStaging() {
    _sleepStagingState = SleepStagingState.stopping;
    _checkIfNeedToCalculateTimer?.cancel();
    _checkIfNeedToCalculateTimer = null;
    if (_sleepCalculationState == SleepCalculationState.waiting) {
      _calculateSleepStagingResults();
    }
  }

  void clearSleepStaging() {
    if (_sleepStagingState == SleepStagingState.stopping) {
      return;
    }
    _sleepCalculationState = SleepCalculationState.waiting;
    _sleepStagingState = SleepStagingState.notStarted;
    _sleepStagingLabels.clear();
    _sleepStagingConfidences.clear();
    _sleepStartTime = null;
  }

  Future _checkIfNeedToCalculate() async {
    if (_sleepCalculationState == SleepCalculationState.waiting) {
      if (DateTime.now().difference(_sleepStartTime!.add(_calculatedDuration)) >=
          _sleepStagingCalculationInterval!) {
        _calculateSleepStagingResults();
      }
    }
  }

  Future _calculateSleepStagingResults() async {
    _sleepCalculationState = SleepCalculationState.calculating;
    Device? device = _deviceManager.getConnectedDevice();
    if (device == null) {
      return null;
    }
    String channelName = '1';
    switch (device.type) {
      case DeviceType.xenon:
        channelName = EarbudsConfigs.getConfig(EarbudsConfigNames.XENON_B_CONFIG.name.toLowerCase())
            .bestSignalChannel.toString();
        break;
      case DeviceType.kauai:
        channelName = EarbudsConfigs.getConfig(EarbudsConfigNames.KAUAI_CONFIG.name.toLowerCase())
            .bestSignalChannel.toString();
        break;
      default:
        break;
    }
    DateTime startTime = _sleepStartTime!.add(_calculatedDuration);
    DateTime endTime = startTime.add(_singleSleepEpoch);
    // Add time epoch by epoch to be able to concatenate the results after calculation.
    while (endTime.isBefore(DateTime.now().subtract(_singleSleepEpoch))) {
      endTime.add(_singleSleepEpoch);
    }
    Duration addedDuration = endTime.difference(startTime);
    Map<String, dynamic>? sleepStagingResults = await NextsenseBase.runSleepStaging(
        macAddress: device.macAddress, localSessionId: _sessionManager.currentLocalSession!,
        channelName: channelName, startDateTime: endTime.subtract(_calculationEpoch),
        duration: _calculationEpoch);
    _calculatedDuration += addedDuration;
    List<dynamic> newSleepStagingResults = sleepStagingResults[_stagingLabelsKey] as List<dynamic>;
    List<dynamic> newSleepConfidences = sleepStagingResults[_confidencesKey] as List<dynamic>;
    int startIndex = ((_calculationEpoch.inSeconds - addedDuration.inSeconds) / 21).round();
    _sleepStagingLabels += newSleepStagingResults.sublist(startIndex);
    _sleepStagingConfidences = newSleepConfidences.sublist(startIndex);
    _sleepCalculationState = SleepCalculationState.waiting;
    if (_sleepStagingState == SleepStagingState.stopping) {
      _sleepStagingState = SleepStagingState.complete;
    }
    _logger.log(Level.INFO, "Finished calculating sleep staging results.");
    notifyListeners();
  }
}