import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:dart_numerics/dart_numerics.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:gson/values.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:scidart/numdart.dart';
import 'package:scidart/scidart.dart';

class XenonImpedanceCalculator {
  static const int defaultTargetFrequency = 10;
  // Manually tweaked with resistors.
  static const double _externalCurrentImpedanceConstant = 13700.94;
  static const double _ads1299AcImpedanceConstant = 338.4;
  // This gives between 500ms and 1000ms of time where calculations can occur.
  static const Duration _channelCycleTime = Duration(milliseconds: 10000);
  // The time period on which a calculation is made.
  static const Duration _impedanceCalculationPeriod =
       Duration(milliseconds: 4096);
  static const double _ads1299AcImpedanceFrequency = 62.5;
  // Maps electrode locations with channels. If more than one, they are added
  // together before doing the FFT.
  static const _locationMappings = {
    'Left Helix': [1, 8],
    'Right Channel': [8],
    'Left Channel': [7]
  };

  final int samplesSize;
  final DeviceManager _deviceManager = GetIt.instance.get<DeviceManager>();
  final Map<String, dynamic> deviceSettings;
  final CustomLogPrinter _logger;
  List<dynamic>? _eegChannelList;
  int? _impedanceDivider;
  double? _impedanceFrequency;
  double? _streamingFrequency;
  int? _localSessionId;
  ImpedanceMode? _impedanceMode;

  XenonImpedanceCalculator({required this.samplesSize,
      required this.deviceSettings}) :
      _logger = getLogger("XenonImpedanceScreen") {
    double samplingFrequency = deviceSettings[
        describeEnum(DeviceSettingsFields.eegSamplingRate)].toSimple();
    _impedanceDivider = (samplingFrequency / defaultTargetFrequency).round();
    _impedanceFrequency = samplingFrequency / _impedanceDivider!;
    _eegChannelList = deviceSettings[
        describeEnum(DeviceSettingsFields.enabledChannels)];
    _streamingFrequency = deviceSettings[
        describeEnum(DeviceSettingsFields.eegStreamingRate)].toSimple();
  }

  Future<bool> startADS1299DcImpedance() async {
    _logger.log(Level.INFO, "Starting impedance check");
    String? macAddress = _deviceManager.getConnectedDevice()?.macAddress;
    if (macAddress == null) {
      return false;
    }
    _localSessionId = await NextsenseBase.startImpedance(
        macAddress, ImpedanceMode.ON_1299_DC, /*channelNumber=*/null,
        /*frequencyDivider=*/null);
    _impedanceMode = ImpedanceMode.ON_1299_DC;
    return true;
  }

  Future<bool> startADS1299AcImpedance() async {
    _logger.log(Level.INFO, "Starting impedance check");
    String? macAddress = _deviceManager.getConnectedDevice()?.macAddress;
    if (macAddress == null) {
      return false;
    }
    _localSessionId = await NextsenseBase.startImpedance(
        macAddress, ImpedanceMode.ON_1299_AC, /*channelNumber=*/null,
        /*frequencyDivider=*/null);
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
        macAddress, ImpedanceMode.ON_EXTERNAL_CURRENT, channelNum,
        _impedanceDivider!);
    return true;
  }

  Future<bool> changeImpedanceConfig(int channelNum) async {
    String? macAddress = _deviceManager.getConnectedDevice()?.macAddress;
    if (macAddress == null) {
      return false;
    }
    // TODO(eric): Do not close notifications when changing config.
    await NextsenseBase.stopStreaming(macAddress);
    if (_localSessionId != null) {
      NextsenseBase.deleteLocalSession(_localSessionId!);
      _localSessionId = null;
    }
    // Need to give the device a small delay so it can be ready to start again.
    await Future.delayed(const Duration(milliseconds: 100), () {});
    return await startExternalCurrentImpedance(channelNum);
  }

  Future stopImpedance() async {
    String? macAddress = _deviceManager.getConnectedDevice()?.macAddress;
    if (macAddress == null) {
      return;
    }
    await NextsenseBase.stopImpedance(macAddress);
    _impedanceMode = null;
  }

  // Calculate the impedance in Ohms from a single channel electrode values.
  Future<double> calculateImpedance(
      List<int> channelNumbers, double impedanceFrequency, double eegFrequency,
      double impedanceConstant) async {
    String? macAddress = _deviceManager.getConnectedDevice()?.macAddress;
    if (macAddress == null || _localSessionId == null) {
      return -1;
    }
    Map<int, List<double>> eegArrays = new HashMap();
    for (int channelNumber in channelNumbers) {
      List<double> eegArray = await NextsenseBase.getChannelData(macAddress,
          _localSessionId!, channelNumber, _impedanceCalculationPeriod);
      // Make sure there are enough samples to calculate a valid value.
      if (eegArray.length < samplesSize) {
        return 0;
      }
      // Make sure all values are valid, there can be dummy 0 values if the
      // channel was disabled before.
      for (double eegValue in eegArray) {
        if (eegValue == 0.0) {
          return 0;
        }
      }
      // Remove the average from every sample to account for DC drift.
      double eegArrayAverage = eegArray.average;
      for (int i = 0; i < eegArray.length; ++i) {
        eegArray[i] -= eegArrayAverage;
      }
      eegArrays[channelNumber] = eegArray;
    }

    List<double> combinedEegArray = List.filled(samplesSize, 0);
    for (int channelNumber in channelNumbers) {
      for (int i = 0; i < eegArrays[channelNumber]!.length; ++i) {
        combinedEegArray[i] += eegArrays[channelNumber]![i];
      }
    }

    ArrayComplex eegArrayComplex = arrayToComplexArray(Array(combinedEegArray));
    // Use a power of 2 for n.
    // int fftSize = nextPowerOf2(samplesSize); crashing.
    int fftSize = 1024;
    eegArrayComplex = fft(eegArrayComplex, n: fftSize);
    double frequencyBinSize = eegFrequency / fftSize;
    int impedanceBinIndex = (impedanceFrequency / frequencyBinSize).round();
    // Get the correct freq bin and normalize the value.
    Complex frequencyBin = eegArrayComplex[impedanceBinIndex] /
        Complex(real: eegArrayComplex.length.toDouble(), imaginary: 0);
    double magnitude =
        sqrt(pow(frequencyBin.real, 2) + pow(frequencyBin.imaginary, 2));
    return magnitude * impedanceConstant;
  }

  Future<Map<int, double>> calculateAllChannelsImpedance(
      ImpedanceMode impedanceMode) async {
    _impedanceMode = impedanceMode;
    HashMap<int, double> impedanceData = new HashMap();
    switch (_impedanceMode!) {
      case ImpedanceMode.ON_EXTERNAL_CURRENT:
        await startExternalCurrentImpedance(_eegChannelList!.first.toSimple());
        for (Integer channel in _eegChannelList!) {
          if (channel.toSimple() != _eegChannelList!.first.toSimple()) {
            await changeImpedanceConfig(channel.toSimple());
          }
          await Future.delayed(_channelCycleTime, () {});
          impedanceData[channel.toSimple()] = await calculateImpedance(
              [channel.toSimple()], _impedanceFrequency!, _streamingFrequency!,
              _externalCurrentImpedanceConstant);
        }
        break;
      case ImpedanceMode.ON_1299_DC:
        await startADS1299DcImpedance();
        await Future.delayed(_channelCycleTime, () {});
        // TODO(eric): Check the leadsOffPositive bits in the
        //             `DeviceInternalState`. Not working on this for now as the
        //             adapter wiring make this method hard to use.
        break;
      case ImpedanceMode.ON_1299_AC:
        await startADS1299AcImpedance();
        await Future.delayed(_channelCycleTime, () {});
          impedanceData[1] = await calculateImpedance(
              [1, 8], _ads1299AcImpedanceFrequency,
              _streamingFrequency!, _ads1299AcImpedanceConstant);
        impedanceData[7] = await calculateImpedance(
            [7], _ads1299AcImpedanceFrequency,
            _streamingFrequency!, _ads1299AcImpedanceConstant);
        impedanceData[8] = await calculateImpedance(
            [8], _ads1299AcImpedanceFrequency,
            _streamingFrequency!, _ads1299AcImpedanceConstant);
        break;
      default:
        throw new UnimplementedError(
            'Impedance mode ${_impedanceMode} is not supported');
    }
    await stopImpedance();
    if (_localSessionId != null) {
      NextsenseBase.deleteLocalSession(_localSessionId!);
      _localSessionId = null;
    }
    return impedanceData;
  }

  Future<Map<String, double?>> calculateAllImpedances() async {
    Map<int, double> impedanceData =
        await calculateAllChannelsImpedance(ImpedanceMode.ON_1299_AC);
    Map<String, double?> impedances = new HashMap();
    impedances['Right Channel'] = impedanceData[8];
    impedances['Left Channel'] = impedanceData[7];
    impedances['Left Helix'] = impedanceData[1]! + impedanceData[8]!;
    return impedances;
  }

  static int nextPowerOf2(int x) {
    // Crash on log2(1024), opened an issue:
    // https://github.com/zlumyo/dart_numerics/issues/6
    return x == 0 ? 1 : pow(2, log2(x)).ceil();
  }

}