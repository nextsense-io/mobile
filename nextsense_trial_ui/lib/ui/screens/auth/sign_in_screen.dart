import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/flavors.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/permissions_manager.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/emphasized_text.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/session_pop_scope.dart';
import 'package:nextsense_trial_ui/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/prepare_device_screen.dart';
import 'package:nextsense_trial_ui/ui/request_permission_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/set_password_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/sign_in_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/intro/study_intro_screen.dart';
import 'package:permission_handler/permission_handler.dart';
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
            child: PageScaffold(
                showBackButton: false,
                showProfileButton: false,
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Spacer(),
                  HeaderText(text: 'Get started'),
                  SizedBox(height: 20),
                  _buildBody(context),
                  Spacer()
                ]))));
  }

  Widget _buildEmailPasswordAuth(BuildContext context, SignInScreenViewModel viewModel) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _UserPasswordSignInInputField(
          field: viewModel.username,
          labelText: "Enter your email",
          // helperText: 'Please contact NextSense support if you did not get an id',
          icon: Icon(Icons.account_circle)),
      _UserPasswordSignInInputField(
          field: viewModel.password,
          obscureText: true,
          labelText: "Enter your password",
          // helperText: 'Contact NextSense to reset your password',
          icon: Icon(Icons.lock)),
      Padding(
          padding: EdgeInsets.all(10.0),
          child: SimpleButton(
              text: MediumText(text: 'Continue', color: NextSenseColors.darkBlue),
              onTap: viewModel.isBusy ? () => {} :
                  () => _signIn(context, AuthMethod.email_password)))
    ]);
  }

  Widget _buildNextSenseAuth(BuildContext context, SignInScreenViewModel viewModel) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _UserPasswordSignInInputField(
          field: viewModel.username,
          labelText: "Enter your id",
          helperText: 'Please contact NextSense support if you did not get an id',
          icon: Icon(Icons.account_circle)),
      _UserPasswordSignInInputField(
          field: viewModel.password,
          obscureText: true,
          labelText: "Enter your password",
          helperText: 'Contact NextSense to reset your password',
          icon: Icon(Icons.lock)),
      Padding(
          padding: EdgeInsets.all(10.0),
          child: SimpleButton(
              text: MediumText(text: 'Continue', color: NextSenseColors.darkBlue),
              onTap: viewModel.isBusy ? () => {} : () => _signIn(context, AuthMethod.user_code)))
    ]);
  }

  Widget _buildGoogleAuth(BuildContext context, SignInScreenViewModel viewModel) {
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

    List<Widget> _signInWidgets = [];

    for (AuthMethod authMethod in viewModel.authMethods) {
      switch (authMethod) {
        case AuthMethod.email_password:
          _signInWidgets.add(_buildEmailPasswordAuth(context, viewModel));
          break;
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
          child: Center(child: Padding(padding: EdgeInsets.all(20), child: EmphasizedText(
            text: viewModel.errorMsg,
            color: NextSenseColors.red,
            textAlign: TextAlign.center),
          ))),
      Visibility(
        visible: viewModel.isBusy,
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    ]);

    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: _signInWidgets));
  }

  Future _signIn(BuildContext context, AuthMethod authMethod) async {
    final viewModel = context.read<SignInScreenViewModel>();
    AuthenticationResult authResult = await viewModel.signIn(authMethod);

    if (authResult != AuthenticationResult.success) {
      var dialogTitle, dialogContent;
      switch (authResult) {
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
          builder: (_) => SimpleAlertDialog(title: dialogTitle, content: dialogContent));
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
      if (permissionRequest.showRequest) {
        await _navigation.navigateTo(RequestPermissionScreen.id, arguments: permissionRequest);
      } else {
        await permissionRequest.permission.request();
      }
    }

    bool studyLoaded = await viewModel.loadCurrentStudy();
    if (!studyLoaded) {
      // Cannot proceed without study data.
      await showDialog(
          context: context,
          builder: (_) => SimpleAlertDialog(
              title: 'Error with your account',
              content: 'Please contact NextSense support and mention that there is an issue with '
                  'your account study setup.'));
      return;
    }

    if (!viewModel.studyIntroShown) {
      await _navigation.navigateTo(StudyIntroScreen.id);
      await viewModel.markCurrentStudyShown();
    }

    // Navigate to the device preparation screen by default, but in case we
    // already have paired device before, then navigate directly to dashboard
    // Note: same logic in startup screen
    // TODO(eric): Might want to add a 'Do not show this again'
    String screen = PrepareDeviceScreen.id;
    if (viewModel.hadPairedDevice) {
      await viewModel.connectToLastPairedDevice();
      screen = DashboardScreen.id;
    }

    _navigation.navigateWithConnectionChecking(screen, replace: true);

    // If there is an initial intent, navigate to the screen that it asks for. If not, navigate to
    // the device scan screen or the dashboard, depending if there is a connection yet.
    if (_navigation.hasInitialIntent()) {
      _navigation.navigateToInitialIntent();
    }
  }
}

class _UserPasswordSignInInputField extends StatelessWidget {
  final ValueNotifier field;
  final String labelText;
  final String? helperText;
  final Icon? icon;
  final bool? obscureText;

  const _UserPasswordSignInInputField(
      {Key? key,
      required this.field,
      required this.labelText,
      this.helperText,
      this.icon,
      this.obscureText})
      : super(key: key);

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
