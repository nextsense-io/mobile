import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/flavors.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/permissions_manager.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/background_decoration.dart';
import 'package:nextsense_trial_ui/ui/components/session_pop_scope.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/prepare_device_screen.dart';
import 'package:nextsense_trial_ui/ui/request_permission_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/set_password_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/sign_in_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen.dart';
import 'package:provider/src/provider.dart';
import 'package:stacked/stacked.dart';

class SignInScreen extends HookWidget {

  static const String id = 'sign_in_screen';

  final _permissionsManager = getIt<PermissionsManager>();
  final _navigation = getIt<Navigation>();

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

  Widget _buildNextSenseAuth(
      BuildContext context, SignInScreenViewModel viewModel) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _UserPasswordSignInInputField(
          field: viewModel.username,
          labelText: "Enter your id",
          helperText:
              'Please contact NextSense support if you did not get an id',
          icon: Icon(Icons.account_circle)),
      _UserPasswordSignInInputField(
          field: viewModel.password,
          obscureText: true,
          labelText: "Enter your password",
          helperText: 'Contact NextSense to reset your password',
          icon: Icon(Icons.lock)),
      Padding(
          padding: EdgeInsets.all(10.0),
          child: ElevatedButton(
            child: const Text('Continue'),
            onPressed: viewModel.isBusy ? () => {} :
                () => _signIn(context, AuthMethod.user_code)
          )
      )
    ]);
  }

  Widget _buildGoogleAuth(
      BuildContext context, SignInScreenViewModel viewModel) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SignInButton(
        Buttons.Google,
        onPressed: () {
          _signIn(context, AuthMethod.google_auth);
        },
      )
    ]);
  }

  Widget _buildBody(BuildContext context) {
    final viewModel = context.watch<SignInScreenViewModel>();

    List<Widget> _signInWidgets = [
      Padding(
        padding: EdgeInsets.all(10.0),
        child: Text(viewModel.appTitle,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                fontFamily: 'Roboto')),
      ),
    ];

    for (AuthMethod authMethod in viewModel.authMethods) {
      switch (authMethod) {
        case AuthMethod.user_code:
          _signInWidgets.add(_buildNextSenseAuth(context, viewModel));
          break;
        case AuthMethod.google_auth:
          _signInWidgets.add(_buildGoogleAuth(context, viewModel));
          break;
      }
    }

    _signInWidgets.addAll([
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
    ]);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
          children: _signInWidgets),
    );
  }

  Future _signIn(BuildContext context, AuthMethod authMethod) async {
    final viewModel = context.read<SignInScreenViewModel>();
    AuthenticationResult authResult =
        await viewModel.signIn(authMethod);

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
        default:
          dialogTitle = 'Error';
          dialogContent = 'Error occurred. Please contact support';
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

    // If the user had a temporary password, first ask to change it before proceeding.
    if (viewModel.isTempPassword) {
      await _navigation.navigateTo(SetPasswordScreen.id, nextRoute: NavigationRoute(pop: true));
    }

    // If there are permissions that need to be granted, go through them one by one with an
    // explanation screen.
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

    // Navigate to the device preparation screen by default, but in case we
    // already have paired device before, then navigate directly to dashboard
    // Note: we have same logic in startup screen
    // TODO(eric): Might want to add a 'Do not show this again'
    String screen = PrepareDeviceScreen.id;
    if (viewModel.hadPairedDevice) {
      await viewModel.connectToLastPairedDevice();
      screen = DashboardScreen.id;
    }

    _navigation.navigateWithConnectionChecking(screen, replace: true);
  }
}

class _UserPasswordSignInInputField extends StatelessWidget {
  final ValueNotifier field;
  final String labelText;
  final String? helperText;
  final Icon? icon;
  final bool? obscureText;

  const _UserPasswordSignInInputField({
    Key? key,
    required this.field,
    required this.labelText,
    this.helperText,
    this.icon,
    this.obscureText
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(10.0),
        child: TextFormField(
          cursorColor: TextSelectionTheme.of(context).cursorColor,
          initialValue: field.value,
          maxLength: 20,
          obscureText: obscureText ?? false,
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
