import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_common/di.dart' as flutter_common_di;
import 'package:flutter_common/managers/firebase_manager.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/preferences.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/auth/sign_in_screen.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';
import 'package:lucid_reality/ui/screens/startup/startup_screen.dart';
import 'package:lucid_reality/utils/notification.dart';
import 'package:provider/provider.dart';
import 'package:receive_intent/receive_intent.dart' as intent;
import 'package:timezone/data/latest.dart' as tz;

import 'di.dart';
import 'managers/auth_manager.dart';
import 'managers/connectivity_manager.dart';

void _initLogging() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
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
    await initDependencies();
    await _initPreferences();
    await initializeNotification();
    runApp(LucidRealityApp());
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack));
}

class LucidRealityApp extends StatelessWidget {
  final Navigation _navigation = getIt<Navigation>();
  final AuthManager _authManager = getIt<AuthManager>();
  final intent.Intent? initialIntent;

  LucidRealityApp({super.key, this.initialIntent});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<ConnectivityManager>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Lucid Reality",
        theme: ThemeData(
          canvasColor: Colors.transparent,
          primaryColor: NextSenseColors.purple,
          backgroundColor: NextSenseColors.backgroundColor,
          primarySwatch: Colors.blue,
          fontFamily: 'Montserrat',
          textTheme: const TextTheme(
            displaySmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Colors.white),
            displayMedium:
                TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
            displayLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
            headlineSmall:
                TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Colors.white),
            headlineLarge:
                TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
            titleSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Colors.white),
            titleMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
            titleLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
            bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
            bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
            bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            labelSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.white),
            labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Colors.white),
          ).apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
          dialogTheme: const DialogTheme(
            backgroundColor: NextSenseColors.backgroundColor,
            contentTextStyle: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.normal,
            ),
          ),
          scaffoldBackgroundColor: NextSenseColors.backgroundColor,
        ),
        home: StreamBuilder<User?>(
          stream: _authManager.firebaseUser,
          builder: (context, snapshot) {
            if (snapshot.hasData || initialIntent != null) {
              if (snapshot.hasData) _authManager.syncUserIdWithDatabase(snapshot.data!.uid);
              return StartupScreen(initialIntent: initialIntent);
            } else {
              return SignInScreen();
            }
          },
        ),
        navigatorKey: _navigation.navigatorKey,
        onGenerateRoute: _navigation.onGenerateRoute,
      ),
    );
  }
}
