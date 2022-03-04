import 'package:get_it/get_it.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/managers/notifications_manager.dart';
import 'package:nextsense_trial_ui/managers/permissions_manager.dart';
import 'package:nextsense_trial_ui/managers/session_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';

GetIt getIt = GetIt.instance;

Future<void> initDependencies() async {
  // The order here matters as some of these components might use a component
  // that was initialised before.
  getIt.registerSingleton<NotificationsManager>(NotificationsManager());
  getIt.registerSingleton<FirestoreManager>(FirestoreManager());
  getIt.registerSingleton<AuthManager>(AuthManager());
  getIt.registerSingleton<PermissionsManager>(PermissionsManager());
  getIt.registerSingleton<DeviceManager>(DeviceManager());
  getIt.registerSingleton<SessionManager>(SessionManager());
  getIt.registerSingleton<StudyManager>(StudyManager());

  await getIt.get<NotificationsManager>().initializePlugin();
}
