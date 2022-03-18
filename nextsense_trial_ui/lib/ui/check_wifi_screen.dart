import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:provider/src/provider.dart';

class CheckWifiScreen extends HookWidget {

  static const String id = 'check_wifi_screen';

  final _preferences = getIt<Preferences>();

  @override
  Widget build(BuildContext context) {
    final connectivityManager = context.watch<ConnectivityManager>();
    final cellularEnabled = useState<bool>(_preferences.getBool(
        PreferenceKey.allowDataTransmissionViaCellular));
    final bool isWifi = connectivityManager.isWifi;
    final bool canProceed = isWifi || cellularEnabled.value;
    return Scaffold(
      appBar: AppBar(
        title: Text('Check Wifi'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                  Container(
                    height: 200,
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