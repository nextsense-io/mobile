import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityState {
  mobile,
  wifi,
  unknown
}

class ConnectivityManager {

  Future<ConnectivityState> getState() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return ConnectivityState.mobile;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return ConnectivityState.wifi;
    }
    return ConnectivityState.unknown;
  }

  Future<bool> isWifiAvailable() async {
    print('[TODO] ConnectivityManager.isWifiAvailable');
    final ConnectivityState state = await getState();
    return state == ConnectivityState.wifi;
  }
}