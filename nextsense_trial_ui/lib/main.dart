import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/managers/notifications_manager.dart';
import 'package:nextsense_trial_ui/managers/permissions_manager.dart';
import 'package:nextsense_trial_ui/managers/session_manager.dart';
import 'package:nextsense_trial_ui/ui/sign_in_screen.dart';

GetIt getIt = GetIt.instance;

void _registerServices() {
  // The order here matters as some of these components might use a component
  // that was initialised before.
  getIt.registerSingleton<NotificationsManager>(NotificationsManager());
  getIt.registerSingleton<FirestoreManager>(FirestoreManager());
  getIt.registerSingleton<AuthManager>(AuthManager());
  getIt.registerSingleton<PermissionsManager>(PermissionsManager());
  getIt.registerSingleton<DeviceManager>(DeviceManager());
  getIt.registerSingleton<SessionManager>(SessionManager());
}

void _initLogging() {
  Logger.root.level = Level.ALL;  // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initLogging();
  await Firebase.initializeApp();
  _registerServices();
  await GetIt.instance.get<NotificationsManager>().initializePlugin();
  NextsenseBase.startService();
  runApp(NextSenseTrialApp());
}

class NextSenseTrialApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NextSense Trial',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SignInScreen(),
    );
  }
}
