import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/ui/components/background_decoration.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:provider/src/provider.dart';

class CheckInternetScreen extends HookWidget {

  static const String id = 'check_internet_screen';

  final _preferences = getIt<Preferences>();

  CheckInternetScreen();

  @override
  Widget build(BuildContext context) {
    final connectivityManager = context.watch<ConnectivityManager>();
    final cellularEnabled = useState<bool>(_preferences.getBool(
        PreferenceKey.allowDataTransmissionViaCellular));
    final bool isWifi = connectivityManager.isWifi;
    final bool canProceed =
        connectivityManager.isConnectionSufficientForCloudSync();
    return Scaffold(
      appBar: AppBar(
        title: Text('Internet Connection'),
      ),
      body: Container(
        decoration: baseBackgroundDecoration,
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
                        Text(
                          isWifi ? "Wifi is connected."
                              : "Wifi is not available!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 30),
                        ),
                        Container(
                          padding: EdgeInsets.all(30.0),
                          child: Text(
                            "A good internet connection is needed to upload your "
                            "NextSense device data to our cloud. Please enable "
                            "your wifi connection or allow cellular upload. Note "
                            "that you should do this only with unmetered plans "
                            "as it could quickly fill your quota.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 20),
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
                      title: const Text('Allow cellular data for transmission',
                        style: TextStyle(color:Colors.white, fontSize: 20),),
                      value: cellularEnabled.value,
                      onChanged: (bool allowCellular) {
                        cellularEnabled.value = allowCellular;
                        _preferences.setBool(
                            PreferenceKey.allowDataTransmissionViaCellular,
                            allowCellular);
                        NextsenseBase.setUploaderMinimumConnectivity(
                            allowCellular ? ConnectivityState.mobile.name :
                            ConnectivityState.wifi.name);
                      },
                      secondary: const Icon(Icons.network_cell, color: Colors.white,),
                    ),
                  ),
                SizedBox(height: 30,),
                ElevatedButton(
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Continue",
                      style: TextStyle(fontSize: 30.0),
                    ),
                  ),
                  onPressed: canProceed ? () async {
                    Navigator.of(context).pop();
                  } : null,
                )
                ],
          )
        ),
      ),
    );
  }
}