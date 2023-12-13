import 'package:flutter_common/di.dart' as common_di;
import 'package:get_it/get_it.dart';
import 'package:lucid_reality/managers/lucid_ui_firebase_realtime_db_manager.dart';
import 'package:lucid_reality/managers/pvt_manager.dart';
import 'package:lucid_reality/preferences.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';

import 'domain/psychomotor_vigilance_test_data_provider.dart';
import 'managers/auth_manager.dart';
import 'managers/connectivity_manager.dart';

GetIt getIt = GetIt.instance;

void initFirebase() {
  common_di.initFirebase();
}

Future<void> initDependencies() async {
  // The order here matters as some of these components might use a component that was initialised
  // before.
  await common_di.initDependencies("/");
  getIt.registerSingleton<LucidUiFirebaseRealtimeDBManager>(LucidUiFirebaseRealtimeDBManager());
  getIt.registerSingleton<Preferences>(Preferences());
  getIt.registerSingleton<ConnectivityManager>(ConnectivityManager());
  getIt.registerSingleton<AuthManager>(AuthManager());
  getIt.registerSingleton<Navigation>(Navigation());
  getIt.registerSingleton<PsychomotorVigilanceTestDataProvider>(
      PsychomotorVigilanceTestDataProvider());
  getIt.registerSingleton<PVTManager>(PVTManager());
}
