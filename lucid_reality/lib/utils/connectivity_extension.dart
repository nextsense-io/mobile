import 'package:lucid_reality/managers/connectivity_manager.dart';

extension ConnectivityExtension on ConnectivityManager {
  Future<bool> hasInternetConnection() async {
    final isConnectedToInternet = await getState();
    return isConnectedToInternet == ConnectivityState.mobile ||
        isConnectedToInternet == ConnectivityState.wifi;
  }
}
