import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_consumer_ui/managers/sleep_staging_manager.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/managers/connectivity_manager.dart';
import 'package:nextsense_consumer_ui/preferences.dart';
import 'package:nextsense_consumer_ui/ui/nextsense_colors.dart';
import 'package:nextsense_consumer_ui/ui/screens/auth/sign_in_screen.dart';
import 'package:nextsense_consumer_ui/ui/screens/startup/startup_screen.dart';
import 'package:provider/provider.dart';
import 'package:receive_intent/receive_intent.dart' as intent;
import 'package:flutter_common/di.dart' as flutter_common_di;
import 'package:flutter_common/managers/firebase_manager.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_consumer_ui/managers/auth_manager.dart';
import 'package:nextsense_consumer_ui/ui/navigation.dart';

void _initLogging() {
  Logger.root.level = Level.ALL;  // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

Future _initFirebase() async {
  flutter_common_di.initFirebase();
  await flutter_common_di.getIt<FirebaseManager>().initializeFirebase();
}

Future _initPreferences() async {
  await getIt<Preferences>().init();
}

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await _initFirebase();
    _initLogging();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    tz.initializeTimeZones();
    NextsenseBase.startService();
    await initDependencies();
    await _initPreferences();
    runApp(NextSenseConsumerApp());
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack));
}

class NextSenseConsumerApp extends StatelessWidget {
  final Navigation _navigation = getIt<Navigation>();
  final AuthManager _authManager = getIt<AuthManager>();
  final intent.Intent? initialIntent;

  NextSenseConsumerApp({super.key, this.initialIntent});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<ConnectivityManager>()),
        ChangeNotifierProvider.value(value: getIt<SleepStagingManager>())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Consumer NextSense",
        theme: ThemeData(
            canvasColor: Colors.transparent,
            primaryColor: NextSenseColors.purple,
            backgroundColor: Colors.white,
            primarySwatch: Colors.blue,
            fontFamily: 'DMMono',
            scaffoldBackgroundColor: Colors.white
        ),
        home: _authManager.isAuthenticated || initialIntent != null ?
        StartupScreen(initialIntent: initialIntent) : SignInScreen(),
        navigatorKey: _navigation.navigatorKey,
        onGenerateRoute: _navigation.onGenerateRoute,
      ),
    );
  }
}

