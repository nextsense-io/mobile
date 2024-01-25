import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_common/managers/device_manager.dart';
import 'package:flutter_common/managers/disk_space_manager.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/article.dart';
import 'package:lucid_reality/ui/screens/dashboard/dashboard_screen.dart';
import 'package:lucid_reality/ui/screens/dream_journal/dream_journal_screen.dart';
import 'package:lucid_reality/ui/screens/learn/article_details.dart';
import 'package:lucid_reality/ui/screens/pvt_onboarding/pvt_onboarding_screen.dart';
import 'package:lucid_reality/ui/screens/reality_check/lucid_reality_category_screen.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_time_screen.dart';
import 'package:receive_intent/receive_intent.dart' as intent;

import 'auth/sign_in_screen.dart';
import 'dream_journal/dream_confirmation_screen.dart';
import 'dream_journal/record_your_dream_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'reality_check/reality_check_bedtime_screen.dart';
import 'reality_check/reality_check_completion_screen.dart';
import 'reality_check/reality_check_tone_category_screen.dart';
import 'reality_check/reality_check_tone_selection_screen.dart';
import 'reality_check/set_goal_screen.dart';
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

  bool hasInitialIntent() {
    return _initialIntent != null;
  }

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
        return MaterialPageRoute(builder: (context) => const OnboardingScreen());
      case DashboardScreen.id:
        return MaterialPageRoute(builder: (context) => DashboardScreen());
      case SignInScreen.id:
        return MaterialPageRoute(builder: (context) => SignInScreen());
      case LucidRealityCategoryScreen.id:
        return MaterialPageRoute(
          builder: (context) => const LucidRealityCategoryScreen(),
          settings: settings,
        );
      case SetGoalScreen.id:
        return MaterialPageRoute(
          builder: (context) => const SetGoalScreen(),
          settings: settings,
        );
      case RealityCheckTimeScreen.id:
        return MaterialPageRoute(
          builder: (context) => RealityCheckTimeScreen(),
          settings: settings,
        );
      case RealityCheckToneCategoryScreen.id:
        return MaterialPageRoute(
          builder: (context) => const RealityCheckToneCategoryScreen(),
          settings: settings,
        );
      case RealityCheckBedtimeScreen.id:
        return MaterialPageRoute(
          builder: (context) => RealityCheckBedtimeScreen(),
          settings: settings,
        );
      case RealityCheckToneSelectionScreen.id:
        return MaterialPageRoute(
          builder: (context) => const RealityCheckToneSelectionScreen(),
          settings: settings,
        );
      case RealityCheckCompletionScreen.id:
        return MaterialPageRoute(builder: (context) => const RealityCheckCompletionScreen());
      case DreamJournalScreen.id:
        return MaterialPageRoute(
          builder: (context) => DreamJournalScreen(),
          settings: settings,
        );
      case DreamConfirmationScreen.id:
        return MaterialPageRoute(
          builder: (context) => const DreamConfirmationScreen(),
          settings: settings,
        );
      case PVTOnboardingScreen.id:
        return MaterialPageRoute(
          builder: (context) => const PVTOnboardingScreen(),
          settings: settings,
        );
      // Routes with arguments
      case RecordYourDreamScreen.id:
        return MaterialPageRoute(builder: (context) => RecordYourDreamScreen(), settings: settings);
      case ArticleDetailsScreen.id:
        return MaterialPageRoute(
            builder: (context) => ArticleDetailsScreen(article: settings.arguments as Article),
            settings: settings);
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

  void popWithResult<T extends Object?>([T? result]) {
    if (canPop()) {
      return navigatorKey.currentState!.pop(result);
    }
  }

  void popUntil(String routeName) {
    final currentState = navigatorKey.currentState!;
    currentState.popUntil(ModalRoute.withName(routeName));
  }
}
