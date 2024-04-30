import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';

import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/preferences.dart';

enum ConnectivityState {
  mobile,
  wifi,
  none,
  unknown
}

/*
 * Determine device connectivity state either Wifi or Cellular
 */
class ConnectivityManager extends ChangeNotifier {

  final _preferences = getIt<Preferences>();

  ConnectivityState state = ConnectivityState.unknown;

  bool get isWifi => state == ConnectivityState.wifi;

  bool get isCellular => state == ConnectivityState.mobile;

  bool get isNone => state == ConnectivityState.none;

  StreamSubscription<ConnectivityResult>? connectivityStream;

  ConnectivityManager() {
    connectivityStream = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      switch (result) {
        case ConnectivityResult.wifi:
          state = ConnectivityState.wifi;
          break;
        case ConnectivityResult.mobile:
          state = ConnectivityState.mobile;
          break;
        case ConnectivityResult.vpn:
        case ConnectivityResult.ethernet:
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.other:
          break;
        case ConnectivityResult.none:
          state = ConnectivityState.none;
          break;
      }
      notifyListeners();
    });

    // Get initial state
    getState().then((state) {
      this.state = state;
    });
  }

  Future<ConnectivityState> getState() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return ConnectivityState.mobile;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return ConnectivityState.wifi;
    } else if (connectivityResult == ConnectivityResult.none) {
      return ConnectivityState.none;
    }
    return ConnectivityState.unknown;
  }

  bool isConnectionSufficientForCloudSync() {
    switch (state) {
      case ConnectivityState.wifi:
        return true;
      case ConnectivityState.mobile:
        return _preferences.getBool(
            PreferenceKey.allowDataTransmissionViaCellular);
      case ConnectivityState.unknown:
      // Fallthrough.
      case ConnectivityState.none:
        return false;
    }
  }
}
