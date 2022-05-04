import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/environment.dart';
import 'package:nextsense_trial_ui/flavors.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/managers/notifications_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/sign_in_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/startup/startup_screen.dart';
import 'package:provider/provider.dart';

import 'utils/android_logger.dart';

void _initLogging() {
  Logger.root.level = Level.ALL;  // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

Future _initPreferences() async {
  initPreferences();
  await getIt<Preferences>().init();
}

Future _initFlavor() async {
  Preferences prefs = getIt<Preferences>();
  String? flavorName = prefs.getString(PreferenceKey.flavor);
  getLogger("Main").log(Level.INFO, "Flavor: $flavorName");
  Flavor flavor = FlavorFactory.createFlavor(flavorName);
  initFlavor(flavor);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initLogging();
  await initEnvironment();
  await Firebase.initializeApp();
  await _initPreferences();
  await _initFlavor();
  await initDependencies();
  await getIt<NotificationsManager>().init();
  NextsenseBase.startService();
  runApp(NextSenseTrialApp());
}

class NextSenseTrialApp extends StatelessWidget {

  final Navigation _navigation = getIt<Navigation>();
  final Flavor _flavor = getIt<Flavor>();
  final AuthManager _authManager = getIt<AuthManager>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<ConnectivityManager>())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: _flavor.appTitle,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: _authManager.isAuthenticated ? StartupScreen() : SignInScreen(),
        navigatorKey: _navigation.navigatorKey,
        onGenerateRoute: _navigation.onGenerateRoute,
      ),
    );
  }
}
