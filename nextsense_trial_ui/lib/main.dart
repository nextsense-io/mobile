
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/environment.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/managers/notifications_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/sign_in_screen.dart';
import 'package:provider/provider.dart';

import 'utils/android_logger.dart';

void _initLogging() {
  Logger.root.level = Level.ALL;  // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initLogging();
  await initEnvironment();
  await Firebase.initializeApp();
  await initDependencies();
  await getIt<Preferences>().init();
  await getIt<NotificationsManager>().init();
  NextsenseBase.startService();
  Preferences prefs = getIt<Preferences>();
  String? flavor = prefs.getString(PreferenceKey.flavor);
  getLogger("XenonImpedanceScreen").log(Level.INFO, "Flavor: $flavor");
  runApp(NextSenseTrialApp());
}

class NextSenseTrialApp extends StatelessWidget {

  final Navigation _navigation = getIt<Navigation>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<ConnectivityManager>())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NextSense Trial',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: SignInScreen(),
        navigatorKey: _navigation.navigatorKey,
        onGenerateRoute: _navigation.onGenerateRoute,
      ),
    );
  }
}
