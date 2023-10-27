import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_common/managers/firebase_manager.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';

import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:receive_intent/receive_intent.dart' as intent;
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
import 'package:timezone/data/latest.dart' as tz;

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
  Environment environment = EnvironmentFactory.createEnvironment(flavorName);
  initEnvironment(environment);
}

Future _initFirebase() async {
  initFirebase();
  await getIt<FirebaseManager>().initializeFirebase();
}

Future<intent.Intent?> _getInitialIntent() async {
  // Platform messages may fail, so we use a try/catch PlatformException.
  try {
    final receivedIntent = await intent.ReceiveIntent.getInitialIntent();
    getLogger("Main").log(Level.INFO, "Initial Intent: $receivedIntent");
    // Validate receivedIntent and warn the user, if it is not correct,
    // but keep in mind it could be `null` or "empty"(`receivedIntent.isNull`).
    if (receivedIntent == null || (receivedIntent.extra == null &&
        receivedIntent.data == null)) {
      getLogger("Main").log(Level.INFO, "Initial intent does not have data or extras, ignoring.");
      return null;
    }
    return receivedIntent;
  } on PlatformException {
    getLogger("Main").log(Level.INFO, "Error getting initial intent.");
  }
  return null;
}

void main() async {
  await _initFirebase();
  runZonedGuarded<Future<void>>(() async {
    _initLogging();
    await initEnvironmentFile();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    tz.initializeTimeZones();
    await _initPreferences();
    await _initFlavor();
    await initDependencies();
    await getIt<NotificationsManager>().init();
    intent.Intent? initialIntent = await _getInitialIntent();
    bool intentGotEmailLink = initialIntent != null && initialIntent.data != null &&
        FirebaseAuth.instance.isSignInWithEmailLink(initialIntent.data!);
    await getIt<Navigation>().init(intentGotEmailLink ? null : initialIntent);
    NextsenseBase.startService();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    runApp(NextSenseTrialApp(initialIntent: intentGotEmailLink ? initialIntent : null));
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack));
}

class NextSenseTrialApp extends StatelessWidget {
  final Navigation _navigation = getIt<Navigation>();
  final Flavor _flavor = getIt<Flavor>();
  final AuthManager _authManager = getIt<AuthManager>();
  final intent.Intent? initialIntent;

  NextSenseTrialApp({this.initialIntent});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<ConnectivityManager>())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: _flavor.appTitle,
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
