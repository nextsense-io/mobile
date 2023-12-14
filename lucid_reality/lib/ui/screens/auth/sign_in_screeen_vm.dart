import 'package:flutter_common/di.dart';
import 'package:flutter_common/managers/auth/auth_method.dart';
import 'package:flutter_common/managers/auth/authentication_result.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/managers/auth_manager.dart';
import 'package:lucid_reality/managers/connectivity_manager.dart';
import 'package:lucid_reality/ui/screens/dashboard/dashboard_screen.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';
import 'package:lucid_reality/ui/screens/onboarding/onboarding_screen.dart';

class SignInViewModel extends ViewModel {
  final Navigation _navigation = getIt<Navigation>();
  final AuthManager _authManager = getIt<AuthManager>();
  final ConnectivityManager _connectivityManager = getIt<ConnectivityManager>();
  
  bool internetConnection = true;
  String errorMsg = "";
  bool popupErrorMsg = false;
  String? initialErrorMessage;
  
  bool get hadPairedDevice => _authManager.getLastPairedMacAddress() != null;
  List<AuthMethod> get authMethods => [AuthMethod.google_auth];
  bool get isTempPassword => _authManager.user!.isTempPassword();

  @override
  void init() async {
    super.init();
    _checkInternetConnection();
  }

  void _checkInternetConnection() {
    if (_connectivityManager.isNone) {
      internetConnection = false;
      errorMsg = "An internet connection is needed to login.";
    } else {
      internetConnection = true;
    }
  }

  void redirectToOnboarding() {
    _navigation.navigateTo(OnboardingScreen.id, replace: true);
  }

  void redirectToDashboard() {
    _navigation.navigateTo(DashboardScreen.id, replace: true);
  }

  Future<AuthenticationResult> signIn(AuthMethod authMethod) async {
    notifyListeners();
    errorMsg = '';
    _checkInternetConnection();
    notifyListeners();
    if (!internetConnection) {
      return AuthenticationResult.connection_error;
    }
    setBusy(true);
    notifyListeners();
    AuthenticationResult authResult;
    switch (authMethod) {
      case AuthMethod.google_auth:
        authResult = await _authManager.signInGoogle();
        break;
      default:
        // Should not happen, but in case should return a generic error to user.
        errorMsg = 'Invalid username or password';
        authResult = AuthenticationResult.error;
        break;
    }
    if (authResult != AuthenticationResult.success) {
      switch (authResult) {
        case AuthenticationResult.user_fetch_failed:
        case AuthenticationResult.invalid_user_setup:
        case AuthenticationResult.invalid_username_or_password:
          errorMsg = 'Invalid username or password';
          break;
        case AuthenticationResult.connection_error:
          errorMsg = 'Connection error';
          break;
        default:
          errorMsg = 'Unknown error occurred';
          break;
      }
      setBusy(false);
      notifyListeners();
    }
    return authResult;
  }
}
