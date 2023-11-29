import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_common/managers/device_manager.dart';
import 'package:flutter_common/managers/disk_space_manager.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/ui/screens/dashboard/dashboard_screen.dart';
import 'package:receive_intent/receive_intent.dart' as intent;

import '../../di.dart';
import 'onboarding/onboarding_screen.dart';
import 'startup/startup_screen.dart';

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
  // static const String _linkExpiredMessage =
  //     'Link is expired or was used already. A new one was sent to your email.';

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final DiskSpaceManager _diskSpaceManager = getIt<DiskSpaceManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('Navigation');

  NavigationRoute? _nextNavigationRoute;
  intent.Intent? _initialIntent;
  String? currentScreenId;

  // Future<void> _initReceiveIntent() async {
  //   _intentSubscription = intent.ReceiveIntent.receivedIntentStream.listen(
  //           (intent.Intent? intent) async {
  //         _logger.log(Level.INFO, "Intent: $intent");
  //         if (intent == null) {
  //           _logger.log(Level.SEVERE, "Intent received with no intent.");
  //           return;
  //         }
  //         await _navigateToIntent(intent);
  //       }, onError: (err) {
  //     _logger.log(Level.INFO, "Error on intent: $err");
  //   });
  //   // No need to call dispose() on the subscription as it runs until the app is stopped.
  // }

  // // Navigate to the target defined in the intent extras.
  // Future<bool> _navigateToIntent(intent.Intent intent, {bool replace = false}) async {
  //   if (intent.extra == null && intent.data == null) {
  //     _logger.log(Level.INFO, "No data or extra in the intent so no navigation is expected.");
  //     return false;
  //   }
  //
  //   if (intent.data != null) {
  //     if (_authManager.email == null) {
  //       await Future.delayed(const Duration(seconds: 0));
  //       await navigateTo(EnterEmailScreen.id);
  //     }
  //     EmailAuthLink emailAuthLink = EmailAuthLink(intent.data!, _authManager.email);
  //     if (!emailAuthLink.isValid) {
  //       _logger.log(Level.WARNING, 'Invalid email auth link: ${emailAuthLink.authLink}');
  //       return false;
  //     }
  //
  //     navigateTo(WaitScreen.id);
  //     bool alreadyLoggedIn = _authManager.isAuthenticated;
  //     AuthenticationResult result =
  //     await _authManager.signInEmailLink(emailAuthLink.authLink, emailAuthLink.email!);
  //     if (result == AuthenticationResult.success) {
  //       pop();
  //       switch (emailAuthLink.urlTarget) {
  //         case UrlTarget.signup:
  //         // fallthrough
  //         case UrlTarget.reset_password:
  //           navigateTo(SetPasswordScreen.id, replace: !alreadyLoggedIn, arguments: false,
  //               nextRoute: NavigationRoute(routeName: StartupScreen.id, popAll: true));
  //           break;
  //         default:
  //       }
  //       return true;
  //     } else {
  //       if (result == AuthenticationResult.expired_link) {
  //         // Send a new email in case it did not work from expiration.
  //         switch (emailAuthLink.urlTarget) {
  //           case UrlTarget.signup:
  //             await _authManager.requestSignUpEmail(emailAuthLink.email!);
  //             break;
  //           case UrlTarget.reset_password:
  //             await _authManager.requestPasswordResetEmail(emailAuthLink.email!);
  //             break;
  //           default:
  //         }
  //       }
  //       if (alreadyLoggedIn) {
  //         Fluttertoast.showToast(
  //             msg: _linkExpiredMessage,
  //             toastLength: Toast.LENGTH_LONG,
  //             gravity: ToastGravity.CENTER,
  //             fontSize: 16.0
  //         );
  //         pop();
  //         return true;
  //       } else {
  //         _authManager.signOut();
  //         pop();
  //         signOut(errorMessage: _linkExpiredMessage);
  //       }
  //       // navigateTo(SetPasswordScreen.id, replace: !alreadyLoggedIn);
  //       // Could not authenticate with the email link, fallback to signin page.
  //       _logger.log(Level.WARNING, 'Failed to authenticate with email link.');
  //       return true;
  //     }
  //   }
  //
  //   if (intent.extra != null) {
  //     if (intent.extra!.containsKey(TargetType.protocol.name)) {
  //       String scheduledProtocolId = intent.extra![TargetType.protocol.name];
  //       _logger.log(Level.INFO, "Scheduled protocol id: $scheduledProtocolId");
  //       ScheduledSession? scheduledProtocol =
  //       await _studyManager.queryScheduledProtocol(scheduledProtocolId);
  //       if (scheduledProtocol != null) {
  //         navigateWithCapabilityChecking(navigatorKey.currentState!.context, ProtocolScreen.id,
  //             replace: replace, arguments: scheduledProtocol);
  //       } else {
  //         _logger.log(Level.SEVERE, "Scheduled protocol $scheduledProtocolId does not exists");
  //       }
  //       return true;
  //     }
  //     if (intent.extra!.containsKey(TargetType.survey.name)) {
  //       String scheduledSurveyId = intent.extra![TargetType.survey.name];
  //       _logger.log(Level.INFO, "Scheduled survey id: $scheduledSurveyId");
  //       ScheduledSurvey? scheduledSurvey =
  //       await _surveyManager.queryScheduledSurvey(scheduledSurveyId);
  //       if (scheduledSurvey != null) {
  //         navigateTo(SurveyScreen.id, replace: replace, arguments: scheduledSurvey);
  //       } else {
  //         _logger.log(Level.SEVERE, "Scheduled survey $scheduledSurveyId does not exists");
  //       }
  //       return true;
  //     }
  //   }
  //   _logger.log(Level.WARNING, "Intent received with no valid target.");
  //   return false;
  // }

  // Future init(intent.Intent? initialIntent) async {
  //   _initialIntent = initialIntent;
  //   await _initReceiveIntent();
  // }

  bool hasInitialIntent() {
    return _initialIntent != null;
  }

  // Future<bool> navigateToInitialIntent() async {
  //   if (_initialIntent != null) {
  //     return await _navigateToIntent(_initialIntent!, replace: false);
  //   }
  //   return false;
  // }

  Future<dynamic> navigateTo(String routeName,
      {Object? arguments,
      bool replace = false,
      bool pop = false,
      bool popAll = false,
      NavigationRoute? nextRoute}) {
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
        pop();
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
      case StartupScreen.id:
        return MaterialPageRoute(builder: (context) => StartupScreen());
      case OnboardingScreen.id:
        return MaterialPageRoute(builder: (context) => OnboardingScreen());
      case DashboardScreen.id:
        return MaterialPageRoute(builder: (context) => DashboardScreen());

      // case ImpedanceCalculationScreen.id: return MaterialPageRoute(
      //     builder: (context) => ImpedanceCalculationScreen());
      // case DashboardScreen.id: return MaterialPageRoute(
      //     builder: (context) => DashboardScreen());
      // case PrepareDeviceScreen.id: return MaterialPageRoute(
      //     builder: (context) => PrepareDeviceScreen());
      // case HelpScreen.id: return MaterialPageRoute(
      //     builder: (context) => HelpScreen());
      // case AboutScreen.id: return MaterialPageRoute(
      //     builder: (context) => AboutScreen());
      // case SupportScreen.id: return MaterialPageRoute(
      //     builder: (context) => const SupportScreen());
      // case SettingsScreen.id: return MaterialPageRoute(
      //     builder: (context) => SettingsScreen());
      // case CheckInternetScreen.id: return MaterialPageRoute(
      //     builder: (context) => CheckInternetScreen());
      // case EnrolledStudiesScreen.id: return MaterialPageRoute(
      //     builder: (context) => EnrolledStudiesScreen());
      // case StudyIntroScreen.id: return MaterialPageRoute(
      //     builder: (context) => StudyIntroScreen());
      // case ProfileScreen.id: return MaterialPageRoute(
      //     builder: (context) => ProfileScreen());
      // case SignalMonitoringScreen.id: return MaterialPageRoute(
      //     builder: (context) => SignalMonitoringScreen());
      // case SurveysScreen.id: return MaterialPageRoute(
      //     builder: (context) => SurveysScreen());
      // case RequestPasswordResetScreen.id: return MaterialPageRoute(
      //     builder: (context) => RequestPasswordResetScreen());
      // case ReAuthenticateScreen.id: return MaterialPageRoute(
      //     builder: (context) => ReAuthenticateScreen());
      // case EarFitScreen.id: return MaterialPageRoute(
      //     builder: (context) => EarFitScreen());
      // case EnterEmailScreen.id: return MaterialPageRoute(
      //     builder: (context) => EnterEmailScreen());
      // case WaitScreen.id: return MaterialPageRoute(
      //     builder: (context) => const WaitScreen());
      // case VisualizationSettingsScreen.id: return MaterialPageRoute(
      //     builder: (context) => VisualizationSettingsScreen());

      // Routes with arguments
      //   case SignInScreen.id: return MaterialPageRoute(
      //       builder: (context) => SignInScreen(initialErrorMessage: settings.arguments as String?));
      // case SetPasswordScreen.id: return MaterialPageRoute(
      //     builder: (context) => SetPasswordScreen(isSignup: settings.arguments as bool));
      // case ProtocolScreen.id:
      //   return MaterialPageRoute(builder: (context) =>
      //       ProtocolScreen(settings.arguments as Protocol));
      // case NapProtocolScreen.id:
      //   return MaterialPageRoute(builder: (context) =>
      //       NapProtocolScreen(settings.arguments as Protocol));
      // case ERPAudioProtocolScreen.id:
      //   return MaterialPageRoute(builder: (context) =>
      //       ERPAudioProtocolScreen(settings.arguments as RunnableProtocol));
      // case EyesMovementProtocolScreen.id:
      //   return MaterialPageRoute(builder: (context) =>
      //       EyesMovementProtocolScreen(settings.arguments as RunnableProtocol));
      // case BioCalibrationProtocolScreen.id:
      //   return MaterialPageRoute(builder: (context) =>
      //       BioCalibrationProtocolScreen(settings.arguments as RunnableProtocol));
      // case SurveyScreen.id:
      //   return MaterialPageRoute(builder: (context) =>
      //       SurveyScreen(settings.arguments as RunnableSurvey));
      // case SeizureScreen.id:
      //   return MaterialPageRoute(builder: (context) =>
      //       SeizureScreen(settings.arguments != null ? settings.arguments as Seizure : null));
      // case SideEffectScreen.id:
      //   return MaterialPageRoute(
      //       builder: (context) => SideEffectScreen(
      //           settings.arguments != null ? settings.arguments as SideEffect : null));
      // case DeviceScanScreen.id: return MaterialPageRoute(
      //     builder: (context) => DeviceScanScreen(autoConnect:
      //     settings.arguments != null ? settings.arguments as bool : false));
      // case EntryAddedScreen.id:
      //   {
      //     assert(settings.arguments != null);
      //     List<dynamic> argsList = settings.arguments as List;
      //     assert(argsList.length >= 2);
      //     return MaterialPageRoute(
      //         builder: (context) => EntryAddedScreen(argsList[0] as String, argsList[1] as Image));
      //   }
      // case RequestPermissionScreen.id:
      //   return MaterialPageRoute(
      //       builder: (context) => RequestPermissionScreen(settings.arguments as PermissionRequest));
      // case InsufficientSpaceScreen.id: return MaterialPageRoute(
      //     builder: (context) => InsufficientSpaceScreen(
      //         settings.arguments as Duration
      //     ));
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
// Future navigateWithCapabilityChecking(BuildContext context, String routeName, {Object? arguments,
//   bool replace = false, bool pop = false}) async {
//   Protocol protocol = arguments as Protocol;
//   if (!(await _diskSpaceManager.isDiskSpaceSufficient(protocol.minDuration))) {
//     await navigateTo(InsufficientSpaceScreen.id,
//         arguments: protocol.minDuration);
//     // Check that the space was cleared before continuing.
//     if (!(await _diskSpaceManager.isDiskSpaceSufficient(protocol.minDuration))) {
//       return;
//     }
//   }
//
//   // ConnectivityManager connectivityManager = context.read<ConnectivityManager>();
//   // if (!connectivityManager.isConnectionSufficientForCloudSync()) {
//   //   _logger.log(Level.INFO, "Connection not sufficient for protocol");
//   //   await navigateTo(CheckInternetScreen.id);
//   //   if (!connectivityManager.isConnectionSufficientForCloudSync()) {
//   //     _logger.log(Level.INFO, "Connection still not sufficient for protocol, pop back");
//   //     return;
//   //   }
//   // }
//
//   if (_deviceManager.getConnectedDevice() == null ||
//       _deviceManager.deviceState.value != DeviceState.ready) {
//     await navigateTo(DeviceScanScreen.id, nextRoute: NavigationRoute(pop: true));
//     if (_deviceManager.getConnectedDevice() == null) {
//       _logger.log(Level.INFO, "Device not connected after scan screen, pop back");
//       return;
//     }
//   }
//
//   _logger.log(Level.INFO, "Navigating to $routeName");
//   await navigateTo(routeName, arguments: arguments, replace: replace, pop: pop);
// }

// // Show connection check screen if needed before navigate to target route
// Future navigateWithConnectionChecking(String routeName,
//     {Object? arguments, bool replace = false, bool pop = false}) async {
//
//   if (!getIt<ConnectivityManager>().isConnectionSufficientForCloudSync()) {
//     await navigateTo(CheckInternetScreen.id);
//   }
//
//   await navigateTo(routeName, arguments: arguments, replace: replace, pop: pop);
// }

// Future signOut({String? errorMessage}) async {
//   await navigateTo(SignInScreen.id, popAll: true, arguments: errorMessage);
// }
}
