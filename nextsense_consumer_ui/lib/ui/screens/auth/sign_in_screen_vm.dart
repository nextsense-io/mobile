import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_common/managers/auth/auth_method.dart';
import 'package:flutter_common/managers/auth/authentication_result.dart';
import 'package:flutter_common/managers/device_manager.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/managers/auth_manager.dart';
import 'package:nextsense_consumer_ui/managers/connectivity_manager.dart';

class SignInScreenViewModel extends ViewModel {
  final AuthManager _authManager = getIt<AuthManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final ConnectivityManager _connectivityManager = getIt<ConnectivityManager>();

  final username = ValueNotifier<String>("");
  final password = ValueNotifier<String>("");

  bool internetConnection = true;
  String errorMsg = "";
  bool popupErrorMsg = false;

  bool get hadPairedDevice => _authManager.getLastPairedMacAddress() != null;
  List<AuthMethod> get authMethods => [AuthMethod.google_auth];
  bool get isTempPassword => _authManager.user!.isTempPassword();
  String? initialErrorMessage;

  SignInScreenViewModel({this.initialErrorMessage}) {
    errorMsg = initialErrorMessage ?? "";
    popupErrorMsg = initialErrorMessage != null;
  }

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
      case AuthMethod.email_password:
        authResult = await _authManager.signInEmailPassword(
            username.value, password.value);
        break;
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
      switch(authResult) {
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

  Future<bool> connectToLastPairedDevice() async {
    setBusy(true);
    bool connected = await _deviceManager.connectToLastPairedDevice(
        _authManager.getLastPairedMacAddress());
    setBusy(false);
    return connected;
  }

  void exit() {
    _deviceManager.dispose();
    NextsenseBase.setFlutterActivityActive(false);
    SystemNavigator.pop();
  }
}