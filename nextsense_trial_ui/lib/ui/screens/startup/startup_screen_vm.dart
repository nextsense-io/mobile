import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/managers/data_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/permissions_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/prepare_device_screen.dart';
import 'package:nextsense_trial_ui/ui/request_permission_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/request_password_reset_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/set_password_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/sign_in_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/intro/study_intro_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_mapping.dart';
import 'package:nextsense_trial_ui/ui/screens/startup/startup_screen.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:receive_intent/receive_intent.dart' as intent;

class StartupScreenViewModel extends ViewModel {

  static const _emailLinkParam = 'email';

  final intent.Intent? initialIntent;

  final CustomLogPrinter _logger = CustomLogPrinter('StartupScreenViewModel');
  final DataManager _dataManager = getIt<DataManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final _permissionsManager = getIt<PermissionsManager>();
  final Navigation _navigation = getIt<Navigation>();

  bool get studyIntroShown => _studyManager.currentEnrolledStudy != null &&
      _studyManager.currentEnrolledStudy!.intro_shown;

  StartupScreenViewModel({this.initialIntent});

  @override
  void init() async {
    setBusy(true);
    super.init();

    // Make sure an internet connection is active before starting. If don't have one, show the login
    // which will display an error.
    if (getIt<ConnectivityManager>().isNone) {
      Future.delayed(Duration(seconds: 0)).then(
              (value) => _navigation.navigateTo(SignInScreen.id, replace: true));
      return;
    }

    // If the authentication was not recent, then setting the password will fail which leads to a
    // bad user experience on first login. Instead send them an email right away and tell them to
    // use it.
    bool justAuthenticated = false;
    // If there is a sign-in link in the intent, process it accordingly.
    if (initialIntent != null && initialIntent!.data != null &&
        FirebaseAuth.instance.isSignInWithEmailLink(initialIntent!.data!)) {
      Uri uri = Uri.parse(initialIntent!.data!);
      _logger.log(Level.INFO, 'Url target: $uri');
      _logger.log(Level.INFO, "emailLink query params: ${uri.queryParameters.values}");
      String? email = uri.queryParameters[_emailLinkParam];
      if (email == null) {
        _logger.log(Level.WARNING,
            "Received an email link with no $_emailLinkParam parameter, cannot process it.");
        await logout(errorMessage:
            'Invalid link, please try to login manually or contact NextSense support');
        return;
      }

      UrlTarget urlTarget = UrlTarget.create(uri.toString());
      if (urlTarget != UrlTarget.unknown) {
        AuthenticationResult result =
            await _authManager.signInEmailLink(initialIntent!.data!, email);
        if (result != AuthenticationResult.success) {
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
          setBusy(false);
          // Could not authenticate with the email link, fallback to signin page.
          _logger.log(Level.SEVERE, 'Failed to authenticate with email link. Fallback to sign in');
          await logout(errorMessage: 'Link is expired or was used already. A new email was sent to your '
              'address.');
          return;
        }
        justAuthenticated = true;
      } else {
        _logger.log(Level.WARNING, 'Unknown url target: ${uri.path}');
        await logout(errorMessage:
            'Invalid link, please login using your password or contact NextSense support.');
        return;
      }
    }

    if (!_dataManager.userLoaded) {
      bool success = false;
      try {
        success = await _dataManager.loadUser();
      } catch (e, stacktrace) {
        _logger.log(Level.SEVERE,
            'load user failed with exception: ${e.toString()}, ${stacktrace.toString()}');
      }
      if (!success) {
        setBusy(false);
        _logger.log(Level.SEVERE, 'Failed to load user. Fallback to sign in');
        await logout();
        return;
      }
    }

    _logger.log(Level.INFO, 'Checking if temporary password.');
    if (_authManager.isTempPassword) {
      setBusy(false);
      if (_authManager.isAuthenticated && justAuthenticated) {
        // If the user got a temp password, make him sign in again and then change it.
        _logger.log(Level.INFO, 'Temporary password. Navigating to password change screen.');
        await _navigation.navigateTo(SetPasswordScreen.id, replace: true,
            nextRoute: NavigationRoute(routeName: StartupScreen.id, replace: true));
      } else {
        _logger.log(Level.INFO, 'Temporary password with no sign-in link.');
        _navigation.navigateTo(RequestPasswordResetScreen.id, replace: true);
        return;
      }
    }

    if (!_dataManager.userStudyDataLoaded) {
      bool success = false;
      try {
        success = await _dataManager.loadUserStudyData();
      } catch (e, stacktrace) {
        _logger.log(Level.SEVERE, 'load user data failed with exception: ${e.toString()}, '
            '${stacktrace.toString()}');
      }
      if (!success) {
        setBusy(false);
        _logger.log(Level.SEVERE, 'Failed to load user. Fallback to sign in');
        await logout();
        return;
      }
    }

    // If there are permissions that need to be granted, go through them one by one with an
    // explanation screen.
    for (PermissionRequest permissionRequest in
        await _permissionsManager.getPermissionsToRequest()) {
      if (permissionRequest.showRequest) {
        await _navigation.navigateTo(RequestPermissionScreen.id, arguments: permissionRequest);
      } else {
        await permissionRequest.permission.request();
      }
    }

    if (!studyIntroShown) {
      await _navigation.navigateTo(StudyIntroScreen.id);
      await markCurrentStudyShown();
    }

    // Navigate to the device preparation screen by default, but in case we already have paired
    // device before, then navigate directly to dashboard. Note: we have same logic in sign in
    // screen.
    String screen = PrepareDeviceScreen.id;
    if (_deviceManager.hadPairedDevice) {
      RunnableProtocol? runnableProtocol = await _authManager.user!.getRunningProtocol();
      if (runnableProtocol != null) {
        bool connected = await _deviceManager.connectToLastPairedDevice();
        if (connected && await _deviceManager.isConnectedDeviceStreaming()) {
          _logger.log(Level.INFO, 'Protocol still running, navigating back to protocol screen.');
          // Protocol still running, go to that screen.
          setBusy(false);
          _navigation.navigateTo(DashboardScreen.id, replace: true);
          _navigation.navigateTo(
              ProtocolScreenMapping.getProtocolScreenId(runnableProtocol.protocol.type),
              arguments: runnableProtocol);
          return;
        } else {
          // Device was shutdown since the app was closed, update the running protocol then go to
          // dashboard/initial intent as usual.
          _logger.log(Level.INFO,
              'Protocol was running but device no longer connected, mark it as canceled.');
          runnableProtocol.update(state: ProtocolState.cancelled);
          _authManager.user!.setRunningProtocol(null);
          _authManager.user!.save();
        }
      }
      screen = DashboardScreen.id;
    }

    if (_navigation.hasInitialIntent()) {
      _navigation.navigateWithConnectionChecking(screen, replace: true);
      _navigation.navigateToInitialIntent();
      setBusy(false);
      return;
    }

    await _navigation.navigateWithConnectionChecking(screen, replace: true).then(
            (value) => _navigation.navigateToInitialIntent());

    setBusy(false);
  }

  Future<bool> markCurrentStudyShown() async {
    return await _studyManager.markEnrolledStudyShown();
  }

  Future logout({String? errorMessage}) async {
    await _authManager.signOut();
    await _navigation.navigateTo(SignInScreen.id, replace: true, arguments: errorMessage);
  }
}