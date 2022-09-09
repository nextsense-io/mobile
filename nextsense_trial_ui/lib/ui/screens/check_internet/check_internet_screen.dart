import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:provider/src/provider.dart';

class CheckInternetScreen extends HookWidget {
  static const String id = 'check_internet_screen';

  final _preferences = getIt<Preferences>();
  final _navigation = getIt<Navigation>();

  CheckInternetScreen();

  @override
  Widget build(BuildContext context) {
    final connectivityManager = context.watch<ConnectivityManager>();
    final cellularEnabled =
        useState<bool>(_preferences.getBool(PreferenceKey.allowDataTransmissionViaCellular));
    final bool isWifi = connectivityManager.isWifi;
    return PageScaffold(
      showBackButton: Navigator.of(context).canPop(),
      showProfileButton: false,
      child: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isWifi ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 60,
                ),
                HeaderText(
                  text: isWifi ? "Wifi is connected." : "Wifi is not available!",
                  color: NextSenseColors.darkBlue,
                ),
                Container(
                  padding: EdgeInsets.all(30.0),
                  child: MediumText(
                    text: "A good internet connection is needed to upload your NextSense device "
                        "data to our cloud. Please enable your wifi connection or allow "
                        "cellular upload. Note that you should do this only with unmetered "
                        "plans as it could quickly fill your quota.",
                    color: NextSenseColors.darkBlue,
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: SwitchListTile(
              activeTrackColor: Colors.grey,
              activeColor: Colors.white,
              title: MediumText(
                  text: 'Allow cellular data for transmission', color: NextSenseColors.darkBlue),
              value: cellularEnabled.value,
              onChanged: (bool allowCellular) {
                cellularEnabled.value = allowCellular;
                _preferences.setBool(PreferenceKey.allowDataTransmissionViaCellular, allowCellular);
                NextsenseBase.setUploaderMinimumConnectivity(
                    allowCellular ? ConnectivityState.mobile.name : ConnectivityState.wifi.name);
              },
              secondary: const Icon(
                Icons.network_cell,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            height: 30,
          ),
          SimpleButton(
            text: MediumText(text: "Continue", color: NextSenseColors.darkBlue),
            onTap: () async {
              if (connectivityManager.isConnectionSufficientForCloudSync()) {
                _navigation.pop();
              }
            },
          )
        ],
      )),
    );
  }
}
