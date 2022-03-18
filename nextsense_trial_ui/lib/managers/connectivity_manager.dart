import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';

enum ConnectivityState {
  mobile,
  wifi,
  unknown
}

/*
 * Determine device connectivity state either Wifi or Cellular
 */
class ConnectivityManager extends ChangeNotifier {

  ConnectivityState state = ConnectivityState.unknown;

  bool get isWifi => state == ConnectivityState.wifi;

  bool get isCellular => state == ConnectivityState.mobile;

  ConnectivityManager() {
    Connectivity().onConnectivityChanged
        .listen((ConnectivityResult result) {
      switch (result) {
        case ConnectivityResult.wifi:
          state = ConnectivityState.wifi;
          break;
        case ConnectivityResult.mobile:
          state = ConnectivityState.mobile;
          break;
        case ConnectivityResult.ethernet:
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.none:
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
    }
    return ConnectivityState.unknown;
  }
}
