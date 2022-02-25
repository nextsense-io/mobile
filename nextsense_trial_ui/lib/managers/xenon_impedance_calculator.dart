import 'dart:collection';

import 'package:collection/collection.dart';
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
  static const double _impedanceConstant = 13700.94;
  // This gives between 500ms and 1000ms of time where calculations can occur.
  static const Duration _channelCycleTime = Duration(milliseconds: 5000);
  // The time period on which a calculation is made.
  static const Duration _impedanceCalculationPeriod =
       Duration(milliseconds: 1000);

  final int samplesSize;
  final DeviceManager _deviceManager = GetIt.instance.get<DeviceManager>();
  final Map<String, dynamic> deviceSettings;
  final CustomLogPrinter _logger;
  List<dynamic>? _eegChannelList;
  int? _impedanceDivider;
  double? _impedanceFrequency;
  double? _streamingFrequency;
  int? _localSessionId;

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

  Future<bool> startImpedance(int channelNum) async {
    _logger.log(Level.INFO, "Starting impedance check");
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
    return await startImpedance(channelNum);
  }

  Future stopImpedance() async {
    String? macAddress = _deviceManager.getConnectedDevice()?.macAddress;
    if (macAddress == null) {
      return;
    }
    await NextsenseBase.stopImpedance(macAddress);
  }

  // Calculate the impedance in Ohms from a single channel electrode values.
  Future<double> calculateImpedance(int channelNumber,
      double impedanceFrequency, double eegFrequency) async {
    String? macAddress = _deviceManager.getConnectedDevice()?.macAddress;
    if (macAddress == null || _localSessionId == null) {
      return -1;
    }
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
    ArrayComplex eegArrayComplex = arrayToComplexArray(Array(eegArray));
    // Use a power of 2 for n.
    eegArrayComplex = fft(eegArrayComplex, n: 256);
    double frequencyBinSize = eegFrequency / 256;
    int impedanceBinIndex = (impedanceFrequency / frequencyBinSize).round();
    // Get the correct freq bin and normalize the value.
    Complex frequencyBin = eegArrayComplex[impedanceBinIndex] /
        Complex(real: eegArrayComplex.length.toDouble(), imaginary: 0);
    double magnitude =
        sqrt(pow(frequencyBin.real, 2) + pow(frequencyBin.imaginary, 2));
    return magnitude * _impedanceConstant;
  }

  Future<HashMap<int, double>> calculateAllChannelsImpedance() async {
    HashMap<int, double> impedanceData = new HashMap();
    await startImpedance(_eegChannelList!.first.toSimple());
    for (Integer channel in _eegChannelList!) {
      if (channel.toSimple() != _eegChannelList!.first.toSimple()) {
        await changeImpedanceConfig(channel.toSimple());
      }
      await Future.delayed(_channelCycleTime, () {});
      impedanceData[channel.toSimple()] = await calculateImpedance(
          channel.toSimple(), _impedanceFrequency!, _streamingFrequency!);
    }
    await stopImpedance();
    if (_localSessionId != null) {
      NextsenseBase.deleteLocalSession(_localSessionId!);
      _localSessionId = null;
    }
    return impedanceData;
  }
}