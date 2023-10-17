import 'package:flutter_common/di.dart' as common_di;
import 'package:get_it/get_it.dart';
import 'package:nextsense_consumer_ui/managers/connectivity_manager.dart';
import 'package:nextsense_consumer_ui/managers/consumer_ui_firestore_manager.dart';
import 'package:nextsense_consumer_ui/managers/event_types_manager.dart';
import 'package:nextsense_consumer_ui/managers/session_manager.dart';

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
  getIt.registerSingleton<ConnectivityManager>(ConnectivityManager());
  getIt.registerSingleton<SessionManager>(SessionManager());
}