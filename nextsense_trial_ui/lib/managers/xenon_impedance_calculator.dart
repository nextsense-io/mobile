import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter_common/domain/device_settings.dart';
import 'package:flutter_common/domain/earbuds_config.dart';
import 'package:flutter_common/managers/device_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:gson/values.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:nextsense_trial_ui/utils/signal_utils.dart';
import 'package:scidart/numdart.dart';
import 'package:scidart/scidart.dart';

class XenonImpedanceCalculator {
  static const double IMPEDANCE_NOT_ENOUGH_DATA = -1.0;
  static const double IMPEDANCE_FLAT_SIGNAL = -2.0;

  static const int _defaultTargetFrequency = 10;

  // Manually tweaked with resistors.
  static const double _externalCurrentImpedanceConstant = 13700.94;

  // Constant tweaked manually to match real resistance numbers from a simulation used to obtain it.
  static const double _ads1299AcImpedanceConstant = 338.4;

  // This gives between 500ms and 1000ms of time where calculations can occur.
  static const Duration _channelCycleTime = Duration(milliseconds: 12000);

  // The time period on which a calculation is made.
  static const Duration _impedanceCalculationPeriod = Duration(milliseconds: 4096);
  // Use a power of 2 of the number of samples.
  static const int _fftSize = 1024;
  static const double _ads1299AcImpedanceFrequency = 62.5;
  static const double _signalMaxValue = 187500.0;
  static const int _flatSignalThresholdPercent = 90;

  final int samplesSize;
  final Map<String, dynamic> deviceSettingsValues;
  final DeviceManager _deviceManager = GetIt.instance.get<DeviceManager>();
  final CustomLogPrinter _logger;

  List<dynamic>? _eegChannelList;
  int? _impedanceDivider;
  double? _impedanceFrequency;
  double? _streamingFrequency;
  int? _localSessionId;
  ImpedanceMode? _impedanceMode;

  XenonImpedanceCalculator({required this.samplesSize, required this.deviceSettingsValues})
      : _logger = getLogger("XenonImpedanceCalculator") {
    DeviceSettings deviceSettings = DeviceSettings(deviceSettingsValues);
    double samplingFrequency = deviceSettings.eegSamplingRate!;
    _impedanceDivider = (samplingFrequency / _defaultTargetFrequency).round();
    _impedanceFrequency = samplingFrequency / _impedanceDivider!;
    _eegChannelList = deviceSettings.enabledChannels;
    _streamingFrequency = deviceSettings.eegStreamingRate;
  }

  Future<bool> startADS1299DcImpedance() async {
    _logger.log(Level.INFO, "Starting impedance check");
    String? macAddress = _deviceManager.getConnectedDevice()?.macAddress;
    if (macAddress == null) {
      return false;
    }
    _localSessionId = await NextsenseBase.startImpedance(
        macAddress, ImpedanceMode.ON_1299_DC, /*channelNumber=*/ null, /*frequencyDivider=*/ null);
    _impedanceMode = ImpedanceMode.ON_1299_DC;
    return true;
  }

  Future<bool> startADS1299AcImpedance() async {
    _logger.log(Level.INFO, "Starting impedance check");
    String? macAddress = _deviceManager.getConnectedDevice()?.macAddress;
    if (macAddress == null) {
      return false;
    }
    try {
      _localSessionId = await NextsenseBase.startImpedance(
          macAddress, ImpedanceMode.ON_1299_AC, /*channelNumber=*/null, /*frequencyDivider=*/null);
    } catch (e) {
      _logger.log(Level.WARNING, "Error starting impedance", e);
      return false;
    }
    _impedanceMode = ImpedanceMode.ON_1299_AC;
    return true;
  }

  Future<bool> startExternalCurrentImpedance(int channelNum) async {
    _logger.log(Level.INFO, "Starting external impedance impedance check");
    String? macAddress = _deviceManager.getConnectedDevice()?.macAddress;
    if (macAddress == null) {
      return false;
    }
    _localSessionId = await NextsenseBase.startImpedance(
        macAddress, ImpedanceMode.ON_EXTERNAL_CURRENT, channelNum, _impedanceDivider!);
    return true;
  }

  Future<bool> changeImpedanceConfig(int channelNum) async {
    String? macAddress = _deviceManager.getConnectedDevice()?.macAddress;
    if (macAddress == null) {
      return false;
    }
    // TODO(eric): Do not close notifications when changing config.
    await _deviceManager.stopStreaming();
    if (_localSessionId != null) {
      NextsenseBase.deleteLocalSession(_localSessionId!);
      _localSessionId = null;
    }
    // Need to give the device a small delay so it can be ready to start again.
    await Future.delayed(const Duration(milliseconds: 100), () {});
    return await startExternalCurrentImpedance(channelNum);
  }

  Future _stopImpedance() async {
    if (_impedanceMode == null) {
      return;
    }
    String? macAddress = _deviceManager.getConnectedDevice()?.macAddress;
    if (macAddress == null) {
      return;
    }
    await NextsenseBase.stopImpedance(macAddress);
    _impedanceMode = null;
  }

  Future stopCalculatingImpedance() async {
    await _stopImpedance();
    if (_localSessionId != null) {
      NextsenseBase.deleteLocalSession(_localSessionId!);
      _localSessionId = null;
    }
  }

  // Calculate the impedance in Ohms from a single channel electrode values.
  Future<double> _calculateImpedance(ImpedanceConfig impedanceConfig, double impedanceFrequency,
      double eegFrequency, double impedanceConstant) async {
    String? macAddress = _deviceManager.getConnectedDevice()?.macAddress;
    if (macAddress == null || _localSessionId == null) {
      return IMPEDANCE_NOT_ENOUGH_DATA;
    }
    _logger.log(Level.INFO, "Starting impedance calculation for $impedanceConfig.");
    Map<int, List<double>> eegArrays = new HashMap();
    List<int> channelNumbers = [impedanceConfig.firstChannel];
    if (impedanceConfig.secondChannel != null) {
      channelNumbers.add(impedanceConfig.secondChannel!);
    }
    for (int channelNumber in channelNumbers) {
      List<double> eegArray = [];
      try {
        DateTime startTime = DateTime.now();
        eegArray = await NextsenseBase.getChannelData(macAddress: macAddress,
            localSessionId: _localSessionId!, channelName: channelNumber.toString(),
            duration: _impedanceCalculationPeriod, fromDatabase: false);
        _logger.log(Level.INFO,
            "read imp data in ${DateTime.now().difference(startTime).inMilliseconds} ms");
      } catch (e) {
        _logger.log(Level.WARNING, "Failed to get channel data: ${e.toString()}");
      }
      // Make sure there are enough samples to calculate a valid value.
      if (eegArray.length < samplesSize) {
        return IMPEDANCE_NOT_ENOUGH_DATA;
      }
      // Make sure all values are valid, there can be dummy 0 values if the
      // channel was disabled before.
      for (double eegValue in eegArray) {
        if (eegValue == 0.0) {
          return IMPEDANCE_NOT_ENOUGH_DATA;
        }
      }
      // Check if the signal is railed or not.
      if (SignalUtils.isSignalFlat(signal: eegArray, maxValue: _signalMaxValue,
          thresholdPercent: _flatSignalThresholdPercent)) {
        return IMPEDANCE_FLAT_SIGNAL;
      }
      // Remove the average from every sample to account for DC drift.
      double eegArrayAverage = eegArray.average;
      for (int i = 0; i < eegArray.length; ++i) {
        eegArray[i] -= eegArrayAverage;
      }
      eegArrays[channelNumber] = eegArray;
    }

    List<double> combinedEegArray = [];
    for (int i = 0; i < channelNumbers.length; ++i) {
      if (i == 0) {
        combinedEegArray = eegArrays[channelNumbers[i]]!;
      } else {
        for (int j = 0; j < eegArrays[channelNumbers[i]]!.length; ++j) {
          combinedEegArray[j] -= eegArrays[channelNumbers[i]]![j];
        }
      }
    }

    ArrayComplex eegArrayComplex = arrayToComplexArray(Array(combinedEegArray));
    eegArrayComplex = fft(eegArrayComplex, n: _fftSize);
    double frequencyBinSize = eegFrequency / _fftSize;
    int impedanceBinIndex = (impedanceFrequency / frequencyBinSize).round();
    // Get the correct freq bin and normalize the value.
    Complex frequencyBin = eegArrayComplex[impedanceBinIndex] /
        Complex(real: eegArrayComplex.length.toDouble() / 2, imaginary: 0);
    double magnitude = sqrt(pow(frequencyBin.real, 2) + pow(frequencyBin.imaginary, 2));
    _logger.log(Level.INFO, "Finished imp calc for channel $channelNumbers");
    return magnitude * impedanceConstant;
  }

  Future<Map<int, double>> calculateExternalChannelsImpedance(EarbudsConfig earbudsConfig) async {
    HashMap<int, double> impedanceData = new HashMap();
    await startExternalCurrentImpedance(_eegChannelList!.first.toSimple());
    for (Integer channel in _eegChannelList!) {
      if (channel.toSimple() != _eegChannelList!.first.toSimple()) {
        await changeImpedanceConfig(channel.toSimple());
      }
      await Future.delayed(_channelCycleTime, () {});
      impedanceData[channel.toSimple()] =
          await _calculateImpedance(ImpedanceConfig.create(
              firstChannel: channel.toSimple()), _impedanceFrequency!,
          _streamingFrequency!, _externalCurrentImpedanceConstant);
    }
    return impedanceData;
  }

  Future<Map<EarLocation, double>> calculate1299AcImpedance(EarbudsConfig earbudsConfig) async {
    HashMap<EarLocation, double> impedanceData = new HashMap();
    for (EarLocation earLocation in earbudsConfig.earLocations.values) {
      if (earLocation.impedanceConfig != null) {
        impedanceData[earLocation] = await _calculateImpedance(earLocation.impedanceConfig!,
            _ads1299AcImpedanceFrequency, _streamingFrequency!, _ads1299AcImpedanceConstant);
      }
    }
    return impedanceData;
  }
}
