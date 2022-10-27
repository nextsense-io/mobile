import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/domain/seizure.dart';
import 'package:nextsense_trial_ui/domain/side_effect.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/disk_space_manager.dart';
import 'package:nextsense_trial_ui/managers/notifications_manager.dart';
import 'package:nextsense_trial_ui/managers/permissions_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/re_authenticate_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/request_password_reset_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/check_internet/check_internet_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/device_scan/device_scan_screen.dart';
import 'package:nextsense_trial_ui/ui/impedance_calculation_screen.dart';
import 'package:nextsense_trial_ui/ui/insufficient_space_screen.dart';
import 'package:nextsense_trial_ui/ui/prepare_device_screen.dart';
import 'package:nextsense_trial_ui/ui/request_permission_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/sign_in_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/surveys_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/profile/profile_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/enrolled_studies/enrolled_studies_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/info/about_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/info/help_screen.dart';
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
import 'package:nextsense_trial_ui/ui/screens/signal/signal_monitoring_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/startup/startup_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/support/support_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/survey/survey_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/set_password_screen.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:provider/provider.dart';

import 'package:receive_intent/receive_intent.dart' as intent;

class NavigationRoute {
  String? routeName;
  Object? arguments;
  bool? replace;
  bool? pop;
  bool? popAll;

  NavigationRoute({this.routeName, this.arguments, this.replace, this.pop, this.popAll});
}

// Possible URLs that can be used to open the application.
// This should match mobile_backend/auth/auth.py UrlTarget enum.
enum UrlTarget {
  signup,
  reset_password,
  unknown;

  factory UrlTarget.create(String url) {
    return values.firstWhere((urlTarget) => url.contains(urlTarget.name), orElse: () => unknown);
  }
}

class Navigation {

  static const _emailLinkParam = 'email';
  static const String _linkExpiredMessage =
      'Link is expired or was used already. A new one was sent to your email.';

  final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();
  final AuthManager _authManager = getIt<AuthManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final DiskSpaceManager _diskSpaceManager = getIt<DiskSpaceManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final SurveyManager _surveyManager = getIt<SurveyManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('Navigation');

  NavigationRoute? _nextNavigationRoute;
  StreamSubscription? _intentSubscription;
  intent.Intent? _initialIntent;
  String? currentScreenId;

  Future<void> _initReceiveIntent() async {
    _intentSubscription = intent.ReceiveIntent.receivedIntentStream.listen(
        (intent.Intent? intent) async {
      _logger.log(Level.INFO, "Intent: $intent");
      if (intent == null) {
        _logger.log(Level.SEVERE, "Intent received with no intent.");
        return;
      }
      await _navigateToIntent(intent);
    }, onError: (err) {
      _logger.log(Level.INFO, "Error on intent: $err");
    });
    // No need to call dispose() on the subscription as it runs until the app is stopped.
  }

  // Navigate to the target defined in the intent extras.
  Future<bool> _navigateToIntent(intent.Intent intent, {bool replace = false}) async {
    if (intent.extra == null || intent.data == null) {
      _logger.log(Level.INFO, "No data or extra in the intent so no navigation is expected.");
      return false;
    }

    if (intent.data != null &&
        FirebaseAuth.instance.isSignInWithEmailLink(intent.data!)) {
      Uri uri = Uri.parse(intent.data!);
      _logger.log(Level.INFO, 'Url target: $uri');
      _logger.log(Level.INFO, "emailLink query params: ${uri.queryParameters.values}");
      String? email = uri.queryParameters[_emailLinkParam];
      if (email == null) {
        _logger.log(Level.WARNING,
            "Received an email link with no $_emailLinkParam parameter, cannot process it.");
        return false;
      }

      UrlTarget urlTarget = UrlTarget.create(uri.toString());
      if (urlTarget == UrlTarget.unknown) {
        _logger.log(Level.WARNING, 'Unknown url target: $uri');
        return false;
      }

      bool alreadyLoggedIn = _authManager.isAuthenticated;
      AuthenticationResult result =
          await _authManager.signInEmailLink(intent.data!, email);
      if (result == AuthenticationResult.success) {
        switch (urlTarget) {
          case UrlTarget.signup:
            // fallthrough
          case UrlTarget.reset_password:
            navigateTo(SetPasswordScreen.id, replace: !alreadyLoggedIn,
                nextRoute: NavigationRoute(routeName: StartupScreen.id, popAll: true));
            break;
          default:
        }
        return true;
      } else {
        if (result == AuthenticationResult.expired_link) {
          // Send a new email in case it did not work from expiration.
          switch (urlTarget) {
            case UrlTarget.signup:
              await _authManager.requestSignUpEmail(email);
              break;
            case UrlTarget.reset_password:
              await _authManager.requestPasswordResetEmail(email);
              break;
            default:
          }
        }
        if (alreadyLoggedIn) {
          Fluttertoast.showToast(
              msg: _linkExpiredMessage,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              fontSize: 16.0
          );
          return true;
        } else {
          _authManager.signOut();
          signOut(errorMessage: _linkExpiredMessage);
        }
        navigateTo(SetPasswordScreen.id, replace: !alreadyLoggedIn);
        // Could not authenticate with the email link, fallback to signin page.
        _logger.log(Level.WARNING, 'Failed to authenticate with email link.');
        return true;
      }
    }

    if (intent.extra != null) {
      if (intent.extra!.containsKey(TargetType.protocol.name)) {
        String scheduledProtocolId = intent.extra![TargetType.protocol.name];
        _logger.log(Level.INFO, "Scheduled protocol id: $scheduledProtocolId");
        ScheduledProtocol? scheduledProtocol =
            await _studyManager.queryScheduledProtocol(scheduledProtocolId);
        if (scheduledProtocol != null) {
          navigateWithCapabilityChecking(navigatorKey.currentState!.context, ProtocolScreen.id,
              replace: replace, arguments: scheduledProtocol);
        } else {
          _logger.log(Level.SEVERE, "Scheduled protocol $scheduledProtocolId does not exists");
        }
        return true;
      }
      if (intent.extra!.containsKey(TargetType.survey.name)) {
        String scheduledSurveyId = intent.extra![TargetType.survey.name];
        _logger.log(Level.INFO, "Scheduled survey id: $scheduledSurveyId");
        ScheduledSurvey? scheduledSurvey =
        await _surveyManager.queryScheduledSurvey(scheduledSurveyId);
        if (scheduledSurvey != null) {
          await navigateTo(SurveyScreen.id, replace: replace, arguments: scheduledSurvey);
        } else {
          _logger.log(Level.SEVERE, "Scheduled survey $scheduledSurveyId does not exists");
        }
        return true;
      }
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
    _logger.log(Level.INFO, "Next route: $nextRoute");
    _nextNavigationRoute = nextRoute;
    final currentState = navigatorKey.currentState!;
    currentScreenId = routeName;
    if (replace) {
      return currentState.pushReplacementNamed(routeName, arguments: arguments);
    }
    if (pop && currentState.canPop()) {
      return currentState.popAndPushNamed(routeName, arguments: arguments);
    }
    if (popAll && currentState.canPop()) {
      return currentState.pushNamedAndRemoveUntil(
          routeName, arguments: arguments, (Route<dynamic> route) => false);
    }
    return currentState.pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic> navigateToNextRoute() {
    if (_nextNavigationRoute == null) {
      _logger.log(Level.INFO, 'no next route');
      return Future.value(false);
    }
    if (_nextNavigationRoute!.routeName == null) {
      _logger.log(Level.INFO, 'no route name');
      if (_nextNavigationRoute!.pop == true) {
        _logger.log(Level.INFO, 'before pop');
        pop();
        _logger.log(Level.INFO, 'after pop');
        return Future.value(true);
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
      case StartupScreen.id: return MaterialPageRoute(
          builder: (context) => StartupScreen());
      case SetPasswordScreen.id: return MaterialPageRoute(
          builder: (context) => SetPasswordScreen());
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
      case SignalMonitoringScreen.id: return MaterialPageRoute(
          builder: (context) => SignalMonitoringScreen());
      case SurveysScreen.id: return MaterialPageRoute(
          builder: (context) => SurveysScreen());
      case RequestPasswordResetScreen.id: return MaterialPageRoute(
          builder: (context) => RequestPasswordResetScreen());
      case ReAuthenticateScreen.id: return MaterialPageRoute(
          builder: (context) => ReAuthenticateScreen());

      // Routes with arguments
      case SignInScreen.id: return MaterialPageRoute(
          builder: (context) => SignInScreen(initialErrorMessage: settings.arguments as String?));
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
      case DeviceScanScreen.id: return MaterialPageRoute(
          builder: (context) => DeviceScanScreen(autoConnect:
              settings.arguments != null ? settings.arguments as bool : false));
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
            builder: (context) => RequestPermissionScreen(settings.arguments as PermissionRequest));
      case InsufficientSpaceScreen.id: return MaterialPageRoute(
          builder: (context) => InsufficientSpaceScreen(
            settings.arguments as Duration
          ));
    }
    return null;
  }

  bool canPop() {
    return navigatorKey.currentState!.canPop();
  }

  void pop() {
    if (canPop()) {
      return navigatorKey.currentState!.pop();
    }
  }

  // Show connection check screen if needed before navigate to target route
  Future navigateWithCapabilityChecking(BuildContext context, String routeName, {Object? arguments,
    bool replace = false, bool pop = false}) async {
    RunnableProtocol runnableProtocol = arguments as RunnableProtocol;
    if (!(await _diskSpaceManager.isDiskSpaceSufficient(runnableProtocol.protocol.minDuration))) {
      await navigateTo(InsufficientSpaceScreen.id,
          arguments: runnableProtocol.protocol.minDuration);
      // Check that the space was cleared before continuing.
      if (!(await _diskSpaceManager.isDiskSpaceSufficient(runnableProtocol.protocol.minDuration))) {
        return;
      }
    }

    ConnectivityManager connectivityManager = context.read<ConnectivityManager>();
    if (!connectivityManager.isConnectionSufficientForCloudSync()) {
      _logger.log(Level.INFO, "Connection not sufficient for protocol");
      await navigateTo(CheckInternetScreen.id);
      if (!connectivityManager.isConnectionSufficientForCloudSync()) {
        _logger.log(Level.INFO, "Connection still not sufficient for protocol, pop back");
        return;
      }
    }

    if (_deviceManager.getConnectedDevice() == null) {
      await navigateTo(DeviceScanScreen.id, nextRoute: NavigationRoute(pop: true));
      if (_deviceManager.getConnectedDevice() == null) {
        _logger.log(Level.INFO, "Device not connected after scan screen, pop back");
        return;
      }
    }

    _logger.log(Level.INFO, "Navigating to $routeName");
    await navigateTo(routeName, arguments: arguments, replace: replace, pop: pop);
  }

  // Show connection check screen if needed before navigate to target route
  Future navigateWithConnectionChecking(String routeName,
      {Object? arguments, bool replace = false, bool pop = false}) async {

    if (!getIt<ConnectivityManager>().isConnectionSufficientForCloudSync()) {
      await navigateTo(CheckInternetScreen.id);
    }

    await navigateTo(routeName, arguments: arguments, replace: replace, pop: pop);
  }

  Future signOut({String? errorMessage}) async {
    await navigateTo(SignInScreen.id, popAll: true, arguments: errorMessage);
  }
}
