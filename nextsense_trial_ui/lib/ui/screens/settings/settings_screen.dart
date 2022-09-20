import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/flavors.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/ui/components/light_header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsScreen extends HookWidget {

  static const String id = 'settings_screen';

  final _preferences = getIt<Preferences>();
  final _flavor = getIt<Flavor>();

  @override
  Widget build(BuildContext context) {

    final cellularEnabled = useState<bool>(_preferences.getBool(
        PreferenceKey.allowDataTransmissionViaCellular));

    final continuousImpedance = useState<bool>(_preferences.getBool(
        PreferenceKey.continuousImpedance));

    return PageScaffold(
      showBackButton: true,
      showProfileButton: false,
      child: SettingsList(
        lightTheme: const SettingsThemeData(settingsListBackground: Colors.transparent),
        sections: [
          SettingsSection(
            title: LightHeaderText(text: 'Common', color: NextSenseColors.darkBlue),
            tiles: <SettingsTile>[
              SettingsTile.switchTile(
                onToggle: (enabled) {
                  cellularEnabled.value = enabled;
                  _preferences.setBool(
                      PreferenceKey.allowDataTransmissionViaCellular, enabled);
                  NextsenseBase.setUploaderMinimumConnectivity(
                      enabled ? ConnectivityState.mobile.name :
                      ConnectivityState.wifi.name);
                },
                initialValue: cellularEnabled.value,
                leading: Icon(Icons.signal_cellular_alt),
                title: MediumText(text: 'Allow cellular data for transmission',
                    color: NextSenseColors.darkBlue),
              )
              ]
          ),
          if (_flavor.userType == UserType.researcher)
            SettingsSection(
              title: Text('Debug'),
              tiles: <SettingsTile>[
                SettingsTile.switchTile(
                  onToggle: (enabled) {
                    continuousImpedance.value = enabled;
                    _preferences.setBool(
                        PreferenceKey.continuousImpedance, enabled);
                  },
                  initialValue: continuousImpedance.value,
                  leading: Icon(Icons.electric_bolt),
                  title: Text('Continuous impedance mode'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}