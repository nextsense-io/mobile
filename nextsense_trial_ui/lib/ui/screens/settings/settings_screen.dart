import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/flavors.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
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
  final _authManager = getIt<AuthManager>();

  @override
  Widget build(BuildContext context) {
    final cellularEnabled =
        useState<bool>(_preferences.getBool(PreferenceKey.allowDataTransmissionViaCellular));
    final continuousImpedance =
        useState<bool>(_preferences.getBool(PreferenceKey.continuousImpedance));
    final medicationNotificationsEnabled =
        useState<bool>(_authManager.user!.isMedicationNotificationsEnabled());
    final surveyNotificationsEnabled =
        useState<bool>(_authManager.user!.isSurveyNotificationsEnabled());
    final recordingNotificationsEnabled =
        useState<bool>(_authManager.user!.isRecordingNotificationsEnabled());

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
                    _preferences.setBool(PreferenceKey.allowDataTransmissionViaCellular, enabled);
                    NextsenseBase.setUploaderMinimumConnectivity(
                        enabled ? ConnectivityState.mobile.name : ConnectivityState.wifi.name);
                  },
                  initialValue: cellularEnabled.value,
                  leading: Icon(Icons.signal_cellular_alt),
                  title: MediumText(
                      text: 'Allow cellular data for transmission',
                      color: NextSenseColors.darkBlue),
                )
              ]),
          SettingsSection(
              title: LightHeaderText(text: 'Notifications', color: NextSenseColors.darkBlue),
              tiles: <SettingsTile>[
                SettingsTile.switchTile(
                  onToggle: (enabled) {
                    medicationNotificationsEnabled.value = enabled;
                    _authManager.user!.setMedicationNotificationsEnabled(enabled);
                    _authManager.user!.save();
                  },
                  initialValue: medicationNotificationsEnabled.value,
                  leading: Icon(Icons.notifications),
                  title: MediumText(text: 'Medications', color: NextSenseColors.darkBlue),
                ),
                SettingsTile.switchTile(
                  onToggle: (enabled) {
                    surveyNotificationsEnabled.value = enabled;
                    _authManager.user!.setSurveyNotificationsEnabled(enabled);
                    _authManager.user!.save();
                  },
                  initialValue: surveyNotificationsEnabled.value,
                  leading: Icon(Icons.notifications),
                  title: MediumText(text: 'Surveys', color: NextSenseColors.darkBlue),
                ),
                SettingsTile.switchTile(
                  onToggle: (enabled) {
                    recordingNotificationsEnabled.value = enabled;
                    _authManager.user!.setRecordingNotificationsEnabled(enabled);
                    _authManager.user!.save();
                  },
                  initialValue: recordingNotificationsEnabled.value,
                  leading: Icon(Icons.notifications),
                  title: MediumText(text: 'EEG Recordings', color: NextSenseColors.darkBlue),
                )
              ]),
          if (_flavor.userType == UserType.researcher)
            SettingsSection(
              title: LightHeaderText(text: 'Debug'),
              tiles: <SettingsTile>[
                SettingsTile.switchTile(
                  onToggle: (enabled) {
                    continuousImpedance.value = enabled;
                    _preferences.setBool(PreferenceKey.continuousImpedance, enabled);
                  },
                  initialValue: continuousImpedance.value,
                  leading: Icon(Icons.electric_bolt),
                  title: MediumText(text: 'Continuous impedance mode',
                      color: NextSenseColors.darkBlue),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
