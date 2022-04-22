import 'package:flutter/material.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/disk_space_manager.dart';
import 'package:nextsense_trial_ui/managers/permissions_manager.dart';
import 'package:nextsense_trial_ui/ui/check_internet_screen.dart';
import 'package:nextsense_trial_ui/ui/device_scan_screen.dart';
import 'package:nextsense_trial_ui/ui/impedance_calculation_screen.dart';
import 'package:nextsense_trial_ui/ui/insufficient_space_screen.dart';
import 'package:nextsense_trial_ui/ui/prepare_device_screen.dart';
import 'package:nextsense_trial_ui/ui/request_permission_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/sign_in_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/info/about_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/info/help_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/info/support_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/eoec_protocol_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/eyes_movement_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/settings/settings_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/survey/survey_screen.dart';
import 'package:nextsense_trial_ui/ui/set_password_screen.dart';
import 'package:nextsense_trial_ui/ui/turn_on_bluetooth_screen.dart';
import 'package:provider/src/provider.dart';

class Navigation {

  final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final DiskSpaceManager _diskSpaceManager = getIt<DiskSpaceManager>();

  Future<dynamic> navigateTo(String routeName, {Object? arguments,
    bool replace = false, bool pop = false}) {
    final currentState = navigatorKey.currentState!;
    if (replace) {
      return currentState.pushReplacementNamed(routeName, arguments: arguments);
    }
    if (pop) {
      return currentState.popAndPushNamed(routeName, arguments: arguments);
    }
    return currentState.pushNamed(routeName, arguments: arguments);
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
  Future navigateWithConnectionChecking(BuildContext context, String routeName, {Object? arguments,
    bool replace = false, bool pop = false}) async {

    if (!context.read<ConnectivityManager>()
        .isConnectionSufficientForCloudSync()) {
      await navigateTo(CheckInternetScreen.id);
    }

    await navigateTo(routeName,
        arguments: arguments, replace: replace, pop: pop);
  }

  void signOut() {
    navigateTo(SignInScreen.id, replace: true);
  }
}
