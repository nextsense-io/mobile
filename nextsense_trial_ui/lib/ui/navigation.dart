import 'package:flutter/material.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/managers/permissions_manager.dart';
import 'package:nextsense_trial_ui/ui/check_wifi_screen.dart';
import 'package:nextsense_trial_ui/ui/device_scan_screen.dart';
import 'package:nextsense_trial_ui/ui/impedance_calculation_screen.dart';
import 'package:nextsense_trial_ui/ui/prepare_device_screen.dart';
import 'package:nextsense_trial_ui/ui/request_permission_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/info/about_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/info/help_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/info/support_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/settings/settings_screen.dart';
import 'package:nextsense_trial_ui/ui/set_password_screen.dart';
import 'package:nextsense_trial_ui/ui/sign_in_screen.dart';
import 'package:nextsense_trial_ui/ui/turn_on_bluetooth_screen.dart';

class Navigation {

  final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();

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
      case CheckWifiScreen.id: return MaterialPageRoute(
          builder: (context) => CheckWifiScreen());
      case HelpScreen.id: return MaterialPageRoute(
          builder: (context) => HelpScreen());
      case AboutScreen.id: return MaterialPageRoute(
          builder: (context) => AboutScreen());
      case SupportScreen.id: return MaterialPageRoute(
          builder: (context) => SupportScreen());
      case SettingsScreen.id: return MaterialPageRoute(
          builder: (context) => SettingsScreen());

    // Routes with arguments
      case ProtocolScreen.id: return MaterialPageRoute(builder: (context) =>
          ProtocolScreen(settings.arguments as Protocol));
      case RequestPermissionScreen.id: return MaterialPageRoute(
          builder: (context) => RequestPermissionScreen(
              settings.arguments as PermissionRequest));
    }
  }

  void pop() {
    return navigatorKey.currentState!.pop();
  }

  Future navigateToDeviceScan({bool replace = false}) async {
    // If wifi not available we ask user to check it
    if (!getIt<ConnectivityManager>().isWifi) {
      await navigateTo(CheckWifiScreen.id);
    }
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
      navigateTo(DeviceScanScreen.id, replace: replace);
    }
  }

  void signOut() {
    navigateTo(SignInScreen.id, replace: true);
  }
}
