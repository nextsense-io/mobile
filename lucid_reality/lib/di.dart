import 'package:flutter_common/di.dart' as common_di;
import 'package:get_it/get_it.dart';
import 'package:lucid_reality/preferences.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';

import 'domain/brain_checking_data_provider.dart';
import 'managers/auth_manager.dart';
import 'managers/connectivity_manager.dart';
import 'managers/consumer_ui_firestore_manager.dart';
import 'managers/data_manager.dart';
import 'managers/event_types_manager.dart';
import 'managers/session_manager.dart';
import 'managers/sleep_staging_manager.dart';

GetIt getIt = GetIt.instance;

void initFirebase() {
  common_di.initFirebase();
}

Future<void> initDependencies() async {
  // The order here matters as some of these components might use a component that was initialised
  // before.
  await common_di.initDependencies("/");
  getIt.registerSingleton<ConsumerUiFirestoreManager>(ConsumerUiFirestoreManager());
  getIt.registerSingleton<EventTypesManager>(EventTypesManager());
  getIt.registerSingleton<Preferences>(Preferences());
  getIt.registerSingleton<ConnectivityManager>(ConnectivityManager());
  getIt.registerSingleton<AuthManager>(AuthManager());
  getIt.registerSingleton<SessionManager>(SessionManager());
  getIt.registerSingleton<DataManager>(DataManager());
  getIt.registerSingleton<Navigation>(Navigation());
  getIt.registerSingleton<SleepStagingManager>(SleepStagingManager());
  getIt.registerSingleton<BrainCheckingDataProvider>(BrainCheckingDataProvider());
}
