import 'package:flutter/foundation.dart';
import 'package:nextsense_base/nextsense_base.dart';

class DeviceSettings {
  late double? eegSamplingRate;
  late double? eegStreamingRate;
  late double? imuSamplingRate;
  late double? imuStreamingRate;
  late List<String> enabledChannels;
  late ImpedanceMode impedanceMode;
  late int? impedanceDivider;

  DeviceSettings(Map<String, dynamic> values) {
    eegSamplingRate = values[describeEnum(DeviceSettingsFields.eegSamplingRate)]?.toSimple();
    eegStreamingRate = values[describeEnum(DeviceSettingsFields.eegStreamingRate)]?.toSimple();
    imuSamplingRate = values[describeEnum(DeviceSettingsFields.imuSamplingRate)]?.toSimple();
    imuStreamingRate = values[describeEnum(DeviceSettingsFields.imuStreamingRate)]?.toSimple();
    enabledChannels = List<String>.from(values[describeEnum(DeviceSettingsFields.enabledChannels)]
        .map((e) => e.toString()).toList());
    // String? impedanceModeValue = values[describeEnum(DeviceSettingsFields.impedanceMode)];
    // if (impedanceModeValue != null) {
    //   print(impedanceModeValue);
    //   impedanceMode = ImpedanceMode.create(int.parse(impedanceModeValue));
    // } else {
    //   impedanceMode = ImpedanceMode.UNKNOWN;
    // }
    impedanceDivider = values[describeEnum(DeviceSettingsFields.impedanceDivider)]?.toSimple();
  }
}