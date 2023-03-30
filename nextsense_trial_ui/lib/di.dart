import 'package:get_it/get_it.dart';
import 'package:nextsense_trial_ui/environment.dart';
import 'package:nextsense_trial_ui/flavors.dart';
import 'package:nextsense_trial_ui/managers/audio_manager.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/managers/data_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/disk_space_manager.dart';
import 'package:nextsense_trial_ui/managers/event_types_manager.dart';
import 'package:nextsense_trial_ui/managers/firebase_manager.dart';
import 'package:nextsense_trial_ui/managers/firebase_storage_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/managers/nextsense_api.dart';
import 'package:nextsense_trial_ui/managers/notifications_manager.dart';
import 'package:nextsense_trial_ui/managers/permissions_manager.dart';
import 'package:nextsense_trial_ui/managers/seizures_manager.dart';
import 'package:nextsense_trial_ui/managers/session_manager.dart';
import 'package:nextsense_trial_ui/managers/side_effects_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';

GetIt getIt = GetIt.instance;

void initPreferences() {
  getIt.registerSingleton<Preferences>(Preferences());
}

void initFlavor(Flavor flavor) {
  getIt.registerSingleton<Flavor>(flavor);
}

void initEnvironment(Environment environment) {
  getIt.registerSingleton<Environment>(environment);
}

void initFirebase() {
  getIt.registerSingleton<FirebaseManager>(FirebaseManager());
}

Future<void> initDependencies() async {
  // The order here matters as some of these components might use a component
  // that was initialised before.
  getIt.registerSingleton<NextsenseApi>(NextsenseApi());
  getIt.registerSingleton<FirestoreManager>(FirestoreManager());
  getIt.registerSingleton<FirebaseStorageManager>(FirebaseStorageManager());
  getIt.registerSingleton<AuthManager>(AuthManager());
  getIt.registerSingleton<NotificationsManager>(NotificationsManager());
  getIt.registerSingleton<PermissionsManager>(PermissionsManager());
  getIt.registerSingleton<DeviceManager>(DeviceManager());
  getIt.registerSingleton<EventTypesManager>(EventTypesManager());
  getIt.registerSingleton<StudyManager>(StudyManager());
  getIt.registerSingleton<SurveyManager>(SurveyManager());
  getIt.registerSingleton<SessionManager>(SessionManager());
  getIt.registerSingleton<DataManager>(DataManager());
  getIt.registerSingleton<SeizuresManager>(SeizuresManager());
  getIt.registerSingleton<SideEffectsManager>(SideEffectsManager());
  getIt.registerSingleton<ConnectivityManager>(ConnectivityManager());
  getIt.registerSingleton<DiskSpaceManager>(DiskSpaceManager());
  getIt.registerSingleton<AudioManager>(AudioManager());
  getIt.registerSingleton<Navigation>(Navigation());
}
