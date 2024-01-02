import 'package:flutter_common/di.dart' as common_di;
import 'package:get_it/get_it.dart';
import 'package:lucid_reality/managers/health_connect_manager.dart';
import 'package:lucid_reality/managers/firebase_storage_manager.dart';
import 'package:lucid_reality/managers/google_fit_manager.dart';
import 'package:lucid_reality/managers/lucid_manager.dart';
import 'package:lucid_reality/managers/lucid_ui_firebase_realtime_db_manager.dart';
import 'package:lucid_reality/managers/pvt_manager.dart';
import 'package:lucid_reality/managers/storage_manager.dart';
import 'package:lucid_reality/preferences.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';

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
  getIt.registerSingleton<HealthConnectManager>(HealthConnectManager());
  getIt.registerSingleton<PVTManager>(PVTManager());
  getIt.registerSingleton<GoogleFitManager>(GoogleFitManager());
  getIt.registerSingleton<LucidManager>(LucidManager());
  getIt.registerSingleton<StorageManager>(StorageManager());
  getIt.registerSingleton<FirebaseStorageManager>(FirebaseStorageManager());
}
