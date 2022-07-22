import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/domain/seizure.dart';
import 'package:nextsense_trial_ui/domain/side_effect.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/disk_space_manager.dart';
import 'package:nextsense_trial_ui/managers/notifications_manager.dart';
import 'package:nextsense_trial_ui/managers/permissions_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:nextsense_trial_ui/ui/check_internet_screen.dart';
import 'package:nextsense_trial_ui/ui/device_scan_screen.dart';
import 'package:nextsense_trial_ui/ui/impedance_calculation_screen.dart';
import 'package:nextsense_trial_ui/ui/insufficient_space_screen.dart';
import 'package:nextsense_trial_ui/ui/prepare_device_screen.dart';
import 'package:nextsense_trial_ui/ui/request_permission_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/sign_in_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/profile/profile_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/enrolled_studies/enrolled_studies_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/info/about_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/info/help_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/info/support_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/intro/study_intro_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/eoec_protocol_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/eyes_movement_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/entry_added_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/seizures/seizure_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/seizures/seizures_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/settings/settings_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/side_effects/side_effect_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/side_effects/side_effects_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/survey/survey_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/set_password_screen.dart';
import 'package:nextsense_trial_ui/ui/turn_on_bluetooth_screen.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:provider/src/provider.dart';
import 'package:receive_intent/receive_intent.dart' as intent;

class NavigationRoute {
  String? routeName;
  Object? arguments;
  bool? replace;
  bool? pop;
  bool? popAll;

  NavigationRoute({this.routeName, this.arguments, this.replace, this.pop, this.popAll});
}

class Navigation {

  final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final DiskSpaceManager _diskSpaceManager = getIt<DiskSpaceManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final SurveyManager _surveyManager = getIt<SurveyManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('Navigation');

  NavigationRoute? _nextNavigationRoute;
  StreamSubscription? _intentSubscription;
  intent.Intent? _initialIntent;

  Future<void> _initReceiveIntent() async {
    _intentSubscription = intent.ReceiveIntent.receivedIntentStream.listen(
            (intent.Intent? intent) async {
      _logger.log(Level.INFO, "Intent: ${intent}");
      if (intent == null) {
        _logger.log(Level.SEVERE, "Intent received with no intent.");
        return;
      }
      await _navigateToIntent(intent);
    }, onError: (err) {
      _logger.log(Level.INFO, "Error on intent: ${err}");
    });
    // No need to call dispose() on the subscription as it runs until the app is stopped.
  }

  // Navigate to the target defined in the intent extras.
  Future<bool> _navigateToIntent(intent.Intent intent, {bool replace = false}) async {
    if (intent.extra == null) {
      _logger.log(Level.INFO, "No extra, probably not a notification that will navigate.");
      return false;
    }
    if (intent.extra!.containsKey(TargetType.protocol.name)) {
      String scheduledProtocolId = intent.extra![TargetType.protocol.name];
      _logger.log(Level.INFO, "Scheduled protocol id: ${scheduledProtocolId}");
      ScheduledProtocol? scheduledProtocol =
      await _studyManager.queryScheduledProtocol(scheduledProtocolId);
      if (scheduledProtocol != null) {
        navigateWithCapabilityChecking(navigatorKey.currentState!.context, ProtocolScreen.id,
            replace: replace, arguments: scheduledProtocol);
      } else {
        _logger.log(Level.SEVERE, "Scheduled protocol ${scheduledProtocolId} does not exists");
      }
      return true;
    }
    if (intent.extra!.containsKey(TargetType.survey.name)) {
      String scheduledSurveyId = intent.extra![TargetType.survey.name];
      _logger.log(Level.INFO, "Scheduled survey id: ${scheduledSurveyId}");
      ScheduledSurvey? scheduledSurvey =
      await _surveyManager.queryScheduledSurvey(scheduledSurveyId);
      if (scheduledSurvey != null) {
        await navigateTo(SurveyScreen.id, replace: replace, arguments: scheduledSurvey);
      } else {
        _logger.log(Level.SEVERE, "Scheduled survey ${scheduledSurveyId} does not exists");
      }
      return true;
    }
    _logger.log(Level.WARNING, "Intent received with no valid target.");
    return false;
  }

  Future init(intent.Intent? initialIntent) async {
    _initialIntent = initialIntent;
    await _initReceiveIntent();
  }

  bool hasInitialIntent() {
    return _initialIntent != null;
  }

  Future<bool> navigateToInitialIntent() async {
    if (_initialIntent != null) {
      return await _navigateToIntent(_initialIntent!, replace: false);
    }
    return false;
  }

  Future<dynamic> navigateTo(String routeName, {Object? arguments,
    bool replace = false, bool pop = false, bool popAll = false, NavigationRoute? nextRoute}) {
    _nextNavigationRoute = nextRoute;
    final currentState = navigatorKey.currentState!;
    if (replace) {
      return currentState.pushReplacementNamed(routeName, arguments: arguments);
    }
    if (pop) {
      return currentState.popAndPushNamed(routeName, arguments: arguments);
    }
    if (popAll) {
      return currentState.pushNamedAndRemoveUntil(routeName, (Route<dynamic> route) => false);
    }
    return currentState.pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic> navigateToNextRoute() {
    if (_nextNavigationRoute == null) {
      return Future.value(false);
    }
    if (_nextNavigationRoute!.routeName == null) {
      if (_nextNavigationRoute!.pop == true) {
        pop();
      }
      return Future.value(false);
    }
    return navigateTo(_nextNavigationRoute!.routeName!,
        arguments: _nextNavigationRoute!.arguments,
        replace: _nextNavigationRoute!.replace ?? false,
        pop: _nextNavigationRoute!.pop ?? false,
        popAll: _nextNavigationRoute!.popAll ?? false,
        nextRoute: null);
  }

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case TurnOnBluetoothScreen.id: return MaterialPageRoute(
          builder: (context) => TurnOnBluetoothScreen());
      case DeviceScanScreen.id: return MaterialPageRoute(
          builder: (context) => DeviceScanScreen());
      case SetPasswordScreen.id: return MaterialPageRoute(
          builder: (context) => SetPasswordScreen());
      case SignInScreen.id: return MaterialPageRoute(
          builder: (context) => SignInScreen());
      case ImpedanceCalculationScreen.id: return MaterialPageRoute(
          builder: (context) => ImpedanceCalculationScreen());
      case DashboardScreen.id: return MaterialPageRoute(
          builder: (context) => DashboardScreen());
      case PrepareDeviceScreen.id: return MaterialPageRoute(
          builder: (context) => PrepareDeviceScreen());
      case HelpScreen.id: return MaterialPageRoute(
          builder: (context) => HelpScreen());
      case AboutScreen.id: return MaterialPageRoute(
          builder: (context) => AboutScreen());
      case SupportScreen.id: return MaterialPageRoute(
          builder: (context) => SupportScreen());
      case SettingsScreen.id: return MaterialPageRoute(
          builder: (context) => SettingsScreen());
      case CheckInternetScreen.id: return MaterialPageRoute(
            builder: (context) => CheckInternetScreen());
      case EnrolledStudiesScreen.id: return MaterialPageRoute(
          builder: (context) => EnrolledStudiesScreen());
      case StudyIntroScreen.id: return MaterialPageRoute(
          builder: (context) => StudyIntroScreen());
      case ProfileScreen.id: return MaterialPageRoute(
          builder: (context) => ProfileScreen());
      case SeizuresScreen.id: return MaterialPageRoute(
          builder: (context) => SeizuresScreen());
      case SideEffectsScreen.id: return MaterialPageRoute(
          builder: (context) => SideEffectsScreen());

      // Routes with arguments
      case ProtocolScreen.id:
        return MaterialPageRoute(builder: (context) =>
            ProtocolScreen(settings.arguments as RunnableProtocol));
      case EOECProtocolScreen.id:
        return MaterialPageRoute(builder: (context) =>
            EOECProtocolScreen(settings.arguments as RunnableProtocol));
      case EyesMovementProtocolScreen.id:
        return MaterialPageRoute(builder: (context) =>
            EyesMovementProtocolScreen(settings.arguments as RunnableProtocol));
      case SurveyScreen.id:
        return MaterialPageRoute(builder: (context) =>
            SurveyScreen(settings.arguments as RunnableSurvey));
      case SeizureScreen.id:
        return MaterialPageRoute(builder: (context) =>
            SeizureScreen(settings.arguments != null ? settings.arguments as Seizure : null));
      case SideEffectScreen.id:
        return MaterialPageRoute(
            builder: (context) => SideEffectScreen(
                settings.arguments != null ? settings.arguments as SideEffect : null));
      case EntryAddedScreen.id:
        {
          assert(settings.arguments != null);
          List<dynamic> argsList = settings.arguments as List;
          assert(argsList.length >= 2);
          return MaterialPageRoute(
              builder: (context) => EntryAddedScreen(argsList[0] as String, argsList[1] as Image));
        }
      case RequestPermissionScreen.id:
        return MaterialPageRoute(
            builder: (context) => RequestPermissionScreen(
              settings.arguments as PermissionRequest));
      case InsufficientSpaceScreen.id: return MaterialPageRoute(
          builder: (context) => InsufficientSpaceScreen(
            settings.arguments as Duration
          ));
    }
  }

  void pop() {
    return navigatorKey.currentState!.pop();
  }

  Future navigateToDeviceScan({bool replace = false}) async {
    // Check if Bluetooth is ON.
    if (!await NextsenseBase.isBluetoothEnabled()) {
      // Ask the user to turn on Bluetooth.
      // Navigate to device scan screen.
      await navigateTo(TurnOnBluetoothScreen.id);
      if (await NextsenseBase.isBluetoothEnabled()) {
        navigateTo(DeviceScanScreen.id, replace: replace);
      }
    } else {
      // Navigate to device scan screen.
      await navigateTo(DeviceScanScreen.id, replace: replace);
    }
  }

  // Show connection check screen if needed before navigate to target route
  Future navigateWithCapabilityChecking(BuildContext context, String routeName, {Object? arguments,
    bool replace = false, bool pop = false}) async {
    RunnableProtocol runnableProtocol = arguments as RunnableProtocol;
    if (!(await _diskSpaceManager.isDiskSpaceSufficient(
        runnableProtocol.protocol.minDuration))) {
      await navigateTo(InsufficientSpaceScreen.id,
          arguments: runnableProtocol.protocol.minDuration);
      // Check that the space was cleared before continuing.
      if (!(await _diskSpaceManager.isDiskSpaceSufficient(
          runnableProtocol.protocol.minDuration))) {
        return;
      }
    }

    if (!context.read<ConnectivityManager>()
        .isConnectionSufficientForCloudSync()) {
      await navigateTo(CheckInternetScreen.id);
      if (!context.read<ConnectivityManager>()
          .isConnectionSufficientForCloudSync()) {
        return;
      }
    }

    if (_deviceManager.getConnectedDevice() == null) {
      await navigateToDeviceScan();
      if (_deviceManager.getConnectedDevice() == null) {
        return;
      }
    }

    await navigateTo(routeName,
        arguments: arguments, replace: replace, pop: pop);
  }

  // Show connection check screen if needed before navigate to target route
  Future navigateWithConnectionChecking(String routeName, {Object? arguments,
    bool replace = false, bool pop = false}) async {

    if (!getIt<ConnectivityManager>()
        .isConnectionSufficientForCloudSync()) {
      await navigateTo(CheckInternetScreen.id);
    }

    await navigateTo(routeName,
        arguments: arguments, replace: replace, pop: pop);
  }

  void signOut() {
    navigateTo(SignInScreen.id, popAll: true);
  }
}
