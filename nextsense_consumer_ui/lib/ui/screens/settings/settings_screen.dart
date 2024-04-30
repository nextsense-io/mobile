import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/managers/connectivity_manager.dart';
import 'package:nextsense_consumer_ui/preferences.dart';
import 'package:nextsense_consumer_ui/ui/components/light_header_text.dart';
import 'package:nextsense_consumer_ui/ui/components/medium_text.dart';
import 'package:nextsense_consumer_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_consumer_ui/ui/nextsense_colors.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsScreen extends HookWidget {
  static const String id = 'settings_screen';

  final _preferences = getIt<Preferences>();

  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cellularEnabled =
        useState<bool>(_preferences.getBool(PreferenceKey.allowDataTransmissionViaCellular));

    return PageScaffold(
      showBackButton: true,
      showProfileButton: false,
      child: SettingsList(
        lightTheme: const SettingsThemeData(settingsListBackground: Colors.transparent),
        sections: [
          SettingsSection(
              title: const LightHeaderText(text: 'Common', color: NextSenseColors.darkBlue),
              tiles: <SettingsTile>[
                SettingsTile.switchTile(
                  onToggle: (enabled) {
                    cellularEnabled.value = enabled;
                    _preferences.setBool(PreferenceKey.allowDataTransmissionViaCellular, enabled);
                    NextsenseBase.setUploaderMinimumConnectivity(
                        enabled ? ConnectivityState.mobile.name : ConnectivityState.wifi.name);
                  },
                  initialValue: cellularEnabled.value,
                  leading: const Icon(Icons.signal_cellular_alt),
                  title: const MediumText(
                      text: 'Allow cellular data for transmission',
                      color: NextSenseColors.darkBlue),
                )
              ]),
        ],
      ),
    );
  }
}
