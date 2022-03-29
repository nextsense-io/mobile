import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/managers/permissions_manager.dart';
import 'package:nextsense_trial_ui/ui/check_internet_screen.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/background_decoration.dart';
import 'package:nextsense_trial_ui/ui/components/session_pop_scope.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/prepare_device_screen.dart';
import 'package:nextsense_trial_ui/ui/request_permission_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/sign_in_screen_vm.dart';
import 'package:provider/src/provider.dart';
import 'package:stacked/stacked.dart';

class SignInScreen extends HookWidget {

  static const String id = 'sign_in_screen';

  final PermissionsManager _permissionsManager = getIt<PermissionsManager>();
  final Navigation _navigation = getIt<Navigation>();
  final ConnectivityManager _connectivityManager = getIt<ConnectivityManager>();

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SignInScreenViewModel>.reactive(
        viewModelBuilder: () => SignInScreenViewModel(),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) => SessionPopScope(
                child: Scaffold(
              body: Container(
                decoration: baseBackgroundDecoration,
                child: _buildBody(context),
              ),
            )));
  }

  Widget _buildBody(BuildContext context) {
    final viewModel = context.watch<SignInScreenViewModel>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
          children: [
        Padding(
          padding: EdgeInsets.all(10.0),
          child: Text('NextSense Trial',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  fontFamily: 'Roboto')),
        ),
        _SignInInputField(
            field: viewModel.username,
            labelText: "Enter your id",
            helperText:
                'Please contact NextSense support if you did not get an id',
            icon: Icon(Icons.account_circle)),
        _SignInInputField(
            field: viewModel.password,
            labelText: "Enter your password",
            helperText: 'Contact NextSense to reset your password',
            icon: Icon(Icons.lock)),
        Visibility(
            visible: viewModel.errorMsg.isNotEmpty,
            child: Text(
                viewModel.errorMsg,
              style: TextStyle(fontSize: 20, color: Color(0xFF5A0000)),
            )
        ),
        Visibility(
          visible: viewModel.isBusy,
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
        Padding(
            padding: EdgeInsets.all(10.0),
            child: ElevatedButton(
              child: const Text('Continue'),
              onPressed: () async {
                _signIn(context);
              },
            ))
      ]),
    );
  }

  Future _signIn(BuildContext context) async {
    final viewModel = context.read<SignInScreenViewModel>();
    AuthenticationResult authResult = await viewModel.signIn();

    if (authResult != AuthenticationResult.success) {
      var dialogTitle, dialogContent;
      switch(authResult) {
        case AuthenticationResult.invalid_username_or_password:
          dialogTitle = 'Invalid password';
          dialogContent = 'The password you entered is invalid';
          break;
        case AuthenticationResult.connection_error:
          dialogTitle = 'Connection error';
          dialogContent = 'An internet connection is needed to validate your '
              'password.';
          break;
        case AuthenticationResult.user_fetch_failed:
        case AuthenticationResult.error:
          dialogTitle = 'Error';
          dialogContent = 'Error occured. Please contact support';
          break;
      }
      await showDialog(
          context: context,
          builder: (_) => SimpleAlertDialog(
              title: dialogTitle,
              content: dialogContent)
      );
      return;
    }

    // If there are permissions that need to be granted, go through them one by
    // one with an explanation screen.
    for (PermissionRequest permissionRequest
    in await _permissionsManager.getPermissionsToRequest()) {
      await _navigation.navigateTo(RequestPermissionScreen.id,
          arguments: permissionRequest);
    }

    bool studyLoaded = await viewModel.loadCurrentStudy();

    if (!studyLoaded) {
      // Cannot proceed without study data.
      await showDialog(
          context: context,
          builder: (_) => SimpleAlertDialog(
              title: 'Error with your account',
              content: 'Please contact NextSense support and mention that there'
                  ' is an issue with your account study setup.')
      );
      return;
    }

    // Navigate to the device preparation screen.
    await _navigation.navigateWithConnectionChecking(
        context, PrepareDeviceScreen.id);
  }

}

class _SignInInputField extends StatelessWidget {
  final ValueNotifier field;
  final String labelText;
  final String? helperText;
  final Icon? icon;

  const _SignInInputField({
    Key? key,
    required this.field,
    required this.labelText,
    this.helperText,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignInScreenViewModel>();
    return Padding(
        padding: EdgeInsets.all(10.0),
        child: TextFormField(
          cursorColor: TextSelectionTheme.of(context).cursorColor,
          initialValue: field.value,
          maxLength: 20,
          //enabled: !_askForPassword,
          decoration: InputDecoration(
            icon: icon,
            labelText: labelText,
            labelStyle: TextStyle(
              color: Color(0xFF6200EE),
            ),
            helperText: helperText,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6200EE)),
            ),
          ),
          onChanged: (newValue) {
            field.value = newValue;
          },
        ));
  }
}
