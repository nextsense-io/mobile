import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/managers/connectivity_manager.dart';
import 'package:nextsense_consumer_ui/ui/nextsense_colors.dart';
import 'package:nextsense_consumer_ui/ui/screens/auth/sign_in_screen.dart';
import 'package:nextsense_consumer_ui/ui/screens/startup/startup_screen.dart';
import 'package:provider/provider.dart';
import 'package:receive_intent/receive_intent.dart' as intent;
import 'package:flutter_common/di.dart' as flutter_common_di;
import 'package:flutter_common/managers/firebase_manager.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_consumer_ui/managers/auth_manager.dart';
import 'package:nextsense_consumer_ui/ui/navigation.dart';

const String _tag = "ConsumerMain";

Future _initFirebase() async {
  flutter_common_di.initFirebase();
  await flutter_common_di.getIt<FirebaseManager>().initializeFirebase();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  getLogger(_tag).log(Level.INFO, "Initial intent does not have data or extras, ignoring.");
  await _initFirebase();
  runZonedGuarded<Future<void>>(() async {
    NextsenseBase.startService();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await initDependencies();
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
        ChangeNotifierProvider.value(value: getIt<ConnectivityManager>())
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

