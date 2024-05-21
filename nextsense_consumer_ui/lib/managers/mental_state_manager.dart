import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_common/di.dart';
import 'package:flutter_common/domain/earbuds_config.dart';
import 'package:flutter_common/managers/device_manager.dart';
import 'package:flutter_common/managers/firebase_storage_manager.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_consumer_ui/managers/auth_manager.dart';
import 'package:nextsense_consumer_ui/managers/session_manager.dart';

enum Band {
  delta(0.5, 4),
  theta(4, 7),
  alpha(7, 12),
  beta(12, 30),
  gamma(30, 49);

  final double bandStart;
  final double bandEnd;

  const Band(this.bandStart, this.bandEnd);
}

enum MentalState {
  unknown,  // Unknown mental state.
  alert,  // Alert state.
  relaxed  // Relaxed state.
}

enum MentalCheckCalculationState {
  calculating,  // Currently calculating sleep staging results.
  waiting  // Currently not calculating sleep staging results.
}

enum MentalChecksState {
  notStarted,  // Not started sleep staging.
  started,  // Started sleep staging, ongoing calculations at regular intervals.
  stopping,  // Stopping sleep staging, finishing the last calculation then will be `complete`.
  complete  // Sleep staging results complete.
}

class MentalStateManager extends ChangeNotifier {
  static const Duration _calculationCheckInterval = Duration(seconds: 5);
  static const Duration _calculationEpoch = Duration(seconds: 40);
  static const double _defaultRelaxedAlphaIncrease = 0.5;

  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final SessionManager _sessionManager = getIt<SessionManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final FirebaseStorageManager _firebaseStorageManager = getIt<FirebaseStorageManager>();
  final List<MentalState> _mentalStates = [];
  final Map<Band, List<double>> _bandPowers = {};
  final _logger = Logger('MentalStateManager');

  // Interval between mental state checks.
  DateTime? _checksStartTime;
  Duration _calculatedDuration = Duration.zero;
  Duration _calculationInterval = Duration.zero;
  Timer? _checkIfNeedToCalculateTimer;
  MentalCheckCalculationState _mentalCheckCalculationState = MentalCheckCalculationState.waiting;
  MentalChecksState _mentalChecksState = MentalChecksState.notStarted;
  MentalState _mentalState = MentalState.unknown;
  double? _powerLineFrequency = null;
  double? _initialAlphaBetaRatio;
  double _relaxedAlphaRatioIncrease = _defaultRelaxedAlphaIncrease;

  MentalState get mentalState => _mentalState;
  MentalCheckCalculationState get mentalCheckCalculationState => _mentalCheckCalculationState;
  List<MentalState> get mentalStates => _mentalStates;
  double get alphaBandPower => _bandPowers[Band.alpha]?.last ?? 0;
  double get betaBandPower => _bandPowers[Band.beta]?.last ?? 0;
  double get thetaBandPower => _bandPowers[Band.theta]?.last ?? 0;
  double get deltaBandPower => _bandPowers[Band.delta]?.last ?? 0;
  double get gammaBandPower => _bandPowers[Band.gamma]?.last ?? 0;
  Map<Band, List<double>?> get bandPowers => _bandPowers;
  double get powerLineFrequency => _powerLineFrequency ?? 0;
  double get relaxedAlphaRatioIncrease => _relaxedAlphaRatioIncrease;

  void startMentalStateChecks({Duration calculationInterval = _calculationCheckInterval}) {
    clearMentalStates();
    _checksStartTime = DateTime.now();
    _calculationInterval = calculationInterval;
    _mentalCheckCalculationState = MentalCheckCalculationState.waiting;
    _mentalChecksState = MentalChecksState.started;
    _mentalState = MentalState.unknown;
    _calculatedDuration = Duration.zero;
    _initialAlphaBetaRatio = null;
    _checkIfNeedToCalculateTimer = Timer.periodic(
      _calculationCheckInterval, (timer) async {
      _checkIfNeedToCalculate();
    });
  }

  void setRelaxedAlphaRatioIncrease(double ratioIncrease) {
    _relaxedAlphaRatioIncrease = ratioIncrease;
  }

  void stopCalculatingMentalStates() {
    _mentalChecksState = MentalChecksState.stopping;
    _checkIfNeedToCalculateTimer?.cancel();
    _checkIfNeedToCalculateTimer = null;
    if (_mentalCheckCalculationState == MentalCheckCalculationState.waiting) {
      _calculateMentalStateResults();
    }
    uploadBandPowerResults();
  }

  void clearMentalStates() {
    if (_mentalChecksState == MentalChecksState.stopping) {
      return;
    }
    _mentalCheckCalculationState = MentalCheckCalculationState.waiting;
    _mentalChecksState = MentalChecksState.notStarted;
    _mentalStates.clear();
    _bandPowers.clear();
    _checksStartTime = null;
    _initialAlphaBetaRatio = null;
  }

  Future uploadBandPowerResults() async {
    DateTime now = DateTime.now();
    String bandPowersCsv = 'alpha,beta,theta,delta,gamma\n';
    if (_bandPowers.isEmpty) {
      _logger.log(Level.INFO, "No band powers to upload.");
      return;
    }
    for (int i = 0; i < _bandPowers[Band.alpha]!.length; i++) {
      bandPowersCsv += '${_bandPowers[Band.alpha]![i]},${_bandPowers[Band.beta]![i]},'
          '${_bandPowers[Band.theta]![i]},${_bandPowers[Band.delta]![i]},'
          '${_bandPowers[Band.gamma]![i]}\n';
    }
    String storageFilePath = '/${_authManager.user?.getEmail()}/mental_state_audio/${now.year}/'
        '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}'
        '/mental_state_audio-${_authManager.user?.getEmail()}-${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-'
        '${now.hour}-${now.minute}-${now.second}_bandpowers.csv';
    String? uploadedFilePath = await _firebaseStorageManager.uploadStringToDataFile(storageFilePath,
        bandPowersCsv);
    _logger.log(Level.INFO, "Uploaded band powers to: ${uploadedFilePath ?? 'No path'}.");
  }

  Future _checkIfNeedToCalculate() async {
    _logger.log(Level.INFO, "Checking if need to calculate mental state...");
    if (_mentalCheckCalculationState == MentalCheckCalculationState.waiting) {
      if (DateTime.now().difference(_checksStartTime!.add(_calculatedDuration)) >=
          _calculationInterval) {
        _calculateMentalStateResults();
      }
    }
  }

  Future<double?> _findPowerLineFrequency(String macAddress, String channelName, startTime) async {
    double fiftyHertzBandPower = await NextsenseBase.getBandPower(
        macAddress: macAddress, localSessionId: _sessionManager.currentLocalSession!,
        channelName: channelName, startTime: startTime,
        bandStart: 49, bandEnd: 51, powerLineFrequency: null,
        duration: _calculationEpoch);
    double sixtyHertzBandPower = await NextsenseBase.getBandPower(
        macAddress: macAddress, localSessionId: _sessionManager.currentLocalSession!,
        channelName: channelName, startTime: startTime,
        bandStart: 59, bandEnd: 61, powerLineFrequency: null,
        duration: _calculationEpoch);
    _logger.log(Level.INFO, "50 hertz band power: $fiftyHertzBandPower\n"
        "60 hertz band power: $sixtyHertzBandPower");
    if (fiftyHertzBandPower == 0 && sixtyHertzBandPower == 0) {
      return null;
    }
    return fiftyHertzBandPower > sixtyHertzBandPower ? 50 : 60;
  }

  Future _calculateMentalStateResults() async {
    _logger.log(Level.INFO, "Calculating mental state...");
    _mentalCheckCalculationState = MentalCheckCalculationState.calculating;
    Device? device = _deviceManager.getConnectedDevice();
    if (device == null || _checksStartTime == null) {
      _mentalCheckCalculationState = MentalCheckCalculationState.waiting;
      return null;
    }
    String channelName = '1';
    switch (device.type) {
      case DeviceType.xenon:
        channelName = EarbudsConfigs.getConfig(EarbudsConfigNames.XENON_B_CONFIG.name.toLowerCase())
            .bestSignalChannel.toString();
        break;
      case DeviceType.kauai:
        channelName = EarbudsConfigs.getConfig(
            EarbudsConfigNames.XENON_P02_CONFIG.name.toLowerCase())
            .bestSignalChannel.toString();
        break;
      case DeviceType.kauai_medical:
        channelName = EarbudsConfigs.getConfig(
            EarbudsConfigNames.KAUAI_MEDICAL_CONFIG.name.toLowerCase())
            .bestSignalChannel.toString();
        break;
      default:
        break;
    }
    DateTime startTime = _checksStartTime!.add(_calculatedDuration);
    DateTime endTime = startTime.add(_calculationEpoch);
    if (endTime.isBefore(DateTime.now())) {
      _powerLineFrequency ??= await _findPowerLineFrequency(
          device.macAddress, channelName, startTime);
      if (_powerLineFrequency == null) {
        _mentalCheckCalculationState = MentalCheckCalculationState.waiting;
        _logger.log(Level.INFO,
            "Could not find power line frequency, skipping power bands calculation.");
        return;
      }
      for (Band band in Band.values) {
        if (!_bandPowers.containsKey(band)) {
          _bandPowers[band] = [];
        }
        _bandPowers[band]!.add(await NextsenseBase.getBandPower(
            macAddress: device.macAddress, localSessionId: _sessionManager.currentLocalSession!,
            channelName: channelName, startTime: startTime,
            bandStart: band.bandStart, bandEnd: band.bandEnd,
            powerLineFrequency: _powerLineFrequency, duration: _calculationEpoch));
      }
      _logger.log(Level.INFO, "Alpha band power: $alphaBandPower\n"
          "Beta band power: $betaBandPower. \n"
          "Theta band power: $thetaBandPower. \n"
          "Delta band power: $deltaBandPower. \n"
          "Gamma band power: $gammaBandPower. \n"
          "Alpha/Beta ratio: ${alphaBandPower / betaBandPower}.");
      int calcEpochs = _bandPowers[Band.alpha]?.length ?? 0;
      if (_initialAlphaBetaRatio != null &&
          (alphaBandPower / betaBandPower) - _initialAlphaBetaRatio! > _relaxedAlphaRatioIncrease) {
        _logger.log(Level.INFO, "Relaxed alpha/beta ratio: ${alphaBandPower / betaBandPower}.");
        _mentalState = MentalState.relaxed;
      } else {
        _mentalState = MentalState.alert;
      }
      if (calcEpochs >= 3) {
        _initialAlphaBetaRatio = alphaBandPower / betaBandPower;
        _logger.log(Level.INFO, "Initial alpha/beta ratio: $_initialAlphaBetaRatio.");
      }
      _calculatedDuration += _calculationEpoch;
      _mentalStates.add(_mentalState);
      _logger.log(Level.INFO, "Adding mental state result: $_mentalState. Total results: "
          "${_mentalStates.length}.");
      notifyListeners();
    } else {
      _logger.log(Level.INFO, "Not enough new data to check mental state.");
    }
    _mentalCheckCalculationState = MentalCheckCalculationState.waiting;
    if (_mentalChecksState == MentalChecksState.stopping) {
      _mentalChecksState = MentalChecksState.complete;
    }
    _logger.log(Level.INFO, "Finished calculating mental states.");
  }
}