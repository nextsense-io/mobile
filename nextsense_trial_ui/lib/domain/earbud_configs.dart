import 'dart:core';

enum EarEegChannel {
  ERW_ELC, // Ear Right Whole Canal - Ear Left Cymba
  ELW_ELC, // Ear Left Whole Canal - Ear Left Cymba
  ELC_ELW, // Ear Left Cymba - Ear Left Whole Canal
  ELC_ERC, // Ear Left Cymba - Ear Right Cymba
  ELC_ERW, // Ear Left Cymba - Ear Right Whole Canal
  ERW_ELW, // Ear Right Whole Canal - Ear Left Whole Canal
  ELW_ERW, // Ear Left Whole Canal - Ear Right Whole Canal
  ELW_ERC, // Ear Left Whole Canal - Ear Right Cymba
  ERW_ERC, // Ear Right Whole Canal - Ear Right Cymba
  ERC_ERW // Ear Right Cymba - Ear Right Whole Canal
}

enum ChannelOperator {
  ADDITION,
  SUBTRACTION
}

enum EarLocationName {
  RIGHT_HELIX,
  RIGHT_CANAL,
  LEFT_HELIX,
  LEFT_CANAL
}

enum EarbudsConfigNames {
  XENON_B_CONFIG,
  KAUAI_CONFIG,
  NITRO_CONFIG
}

class ImpedanceConfig {
  int firstChannel;
  ChannelOperator? channelOperator;
  int? secondChannel;

  static ImpedanceConfig create(
      {required int firstChannel, ChannelOperator? channelOperator, int? secondChannel}) {
    if (channelOperator != null || secondChannel != null) {
      if (channelOperator == null || secondChannel == null) {
        throw ArgumentError.value("Both channelOperator or secondChannel need to be provided if "
            "one of them is provided.");
      }
      return ImpedanceConfig._(firstChannel: firstChannel, secondChannel: secondChannel,
          channelOperator: channelOperator);
    }
    return ImpedanceConfig._(firstChannel: firstChannel);
  }

  ImpedanceConfig._(
      {required int firstChannel, ChannelOperator? channelOperator, int? secondChannel}) :
        this.firstChannel = firstChannel,
        this.channelOperator = channelOperator,
        this.secondChannel = secondChannel;

  @override
  String toString() {
    String text = "$firstChannel";
    if (secondChannel != null) {
      text += " ${channelOperator.toString()} $secondChannel";
    }
    return text;
  }
}

class EarLocation {
  EarLocationName name;
  ImpedanceConfig? impedanceConfig;

  EarLocation({required EarLocationName name, ImpedanceConfig? impedanceConfig}) :
        this.name = name,
        this.impedanceConfig = impedanceConfig;

  String getDisplayName() {
    return name.name.toLowerCase().replaceAll('_', ' ');
  }
}

class EarbudsConfig {
  String name;
  Map<int, EarEegChannel> channelsConfig;
  Map<EarLocationName, EarLocation> earLocations;

  EarbudsConfig({required this.name, required this.channelsConfig, required this.earLocations});
}


class EarbudsConfigs {
  static final Map<String, EarbudsConfig> _earbudsConfigs = {
    EarbudsConfigNames.XENON_B_CONFIG.name.toLowerCase():
        EarbudsConfig(name: EarbudsConfigNames.XENON_B_CONFIG.name.toLowerCase(),
            channelsConfig: {
              1: EarEegChannel.ERW_ELC,
              3: EarEegChannel.ELW_ELC,
              6: EarEegChannel.ELW_ERW,
              7: EarEegChannel.ELW_ERC,
              8: EarEegChannel.ERW_ERC
            },
            earLocations: {
              EarLocationName.RIGHT_CANAL: EarLocation(name: EarLocationName.RIGHT_CANAL,
                  impedanceConfig: ImpedanceConfig.create(firstChannel: 8)),
              // Cannot calculate the right helix impedance with this config
              EarLocationName.RIGHT_HELIX: EarLocation(name: EarLocationName.RIGHT_HELIX),
              EarLocationName.LEFT_CANAL: EarLocation(name: EarLocationName.LEFT_CANAL,
                  impedanceConfig: ImpedanceConfig.create(firstChannel: 7)),
              EarLocationName.LEFT_HELIX: EarLocation(name: EarLocationName.LEFT_HELIX,
                  impedanceConfig: ImpedanceConfig.create(firstChannel: 8,
                      channelOperator: ChannelOperator.SUBTRACTION,
                      secondChannel: 1)),
            }),
    EarbudsConfigNames.KAUAI_CONFIG.name.toLowerCase():
        EarbudsConfig(name: EarbudsConfigNames.KAUAI_CONFIG.name.toLowerCase(),
            channelsConfig: {
              1: EarEegChannel.ERW_ERC,
              2: EarEegChannel.ELW_ERC,
              3: EarEegChannel.ELC_ERC,
              4: EarEegChannel.ERW_ELW,
              5: EarEegChannel.ELW_ELC,
              6: EarEegChannel.ELC_ERW,
            },
            // TODO(eric): Verify if these are correct.
            earLocations: {
              EarLocationName.RIGHT_CANAL: EarLocation(name: EarLocationName.RIGHT_CANAL,
                  impedanceConfig: ImpedanceConfig.create(firstChannel: 1)),
              // Cannot calculate the right helix impedance with this config
              EarLocationName.RIGHT_HELIX: EarLocation(name: EarLocationName.RIGHT_HELIX),
              EarLocationName.LEFT_CANAL: EarLocation(name: EarLocationName.LEFT_CANAL,
                  impedanceConfig: ImpedanceConfig.create(firstChannel: 2)),
              EarLocationName.LEFT_HELIX: EarLocation(name: EarLocationName.LEFT_HELIX,
                  impedanceConfig: ImpedanceConfig.create(firstChannel: 1,
                      channelOperator: ChannelOperator.SUBTRACTION,
                      secondChannel: 6)),
            }),
  };
  
  static EarbudsConfig getConfig(String configName) {
    if (!_earbudsConfigs.containsKey(configName)) {
      throw ArgumentError.value("Unknown earbuds configuration: $configName");
    }
    return _earbudsConfigs[configName]!;
  }
}