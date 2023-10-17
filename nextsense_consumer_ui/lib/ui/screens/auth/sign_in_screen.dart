import 'package:flutter/material.dart';
import 'package:flutter_common/managers/auth/auth_method.dart';
import 'package:flutter_common/managers/auth/authentication_result.dart';
import 'package:flutter_common/managers/auth/email_auth_manager.dart';
import 'package:flutter_common/managers/permissions_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:flutter_common/ui/components/session_pop_scope.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/ui/components/medium_text.dart';
import 'package:nextsense_consumer_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_consumer_ui/ui/navigation.dart';
import 'package:nextsense_consumer_ui/ui/nextsense_colors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class SignInScreen extends HookWidget {
  static const String id = 'sign_in_screen';

  final _permissionsManager = getIt<PermissionsManager>();
  final _navigation = getIt<Navigation>();

  String? initialErrorMessage;
  bool authenticating = false;

  SignInScreen({super.key, this.initialErrorMessage});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SignInScreenViewModel>.reactive(
        viewModelBuilder: () => SignInScreenViewModel(initialErrorMessage: initialErrorMessage),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) => SessionPopScope(
            child: PageScaffold(
                showBackButton: false,
                showProfileButton: false,
                child: ScrollableColumn(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [const Spacer(), HeaderText(text: 'Get started'),
                      const SizedBox(height: 20)] +
                        _buildBody(context) +
                        [
                          const Spacer(),
                          SmallText(text:
                          'By creating a new account, you are agreeing to our Terms of Service '
                              'and Privacy Policy.'),
                        ]))));
  }

  List<Widget> _buildEmailPasswordAuth(BuildContext context, SignInScreenViewModel viewModel) {
    return [
      RoundedBackground(
          child: Column(children: [
            _UserPasswordSignInInputField(
                field: viewModel.username,
                labelText: 'Email',
                maxLength: EmailAuthManager.maxEmailLength),
            // helperText: 'Please contact NextSense support if you did not get an id',
            _UserPasswordSignInInputField(
              field: viewModel.password,
              obscureText: true,
              labelText: 'Password',
              maxLength: EmailAuthManager.maxPasswordLength,
              // helperText: 'Contact NextSense to reset your password',
            )
          ])),
      const SizedBox(height: 20),
      AbsorbPointer(absorbing: authenticating, child:
      SimpleButton(
          fullWidth: true,
          text: const MediumText(
            text: 'Login',
            color: NextSenseColors.purple,
            textAlign: TextAlign.center,
          ),
          onTap: authenticating ? () => {} :
              () => _signIn(context, AuthMethod.email_password))
      ),
      const SizedBox(height: 20),
      Align(
          alignment: Alignment.center,
          child: AbsorbPointer(absorbing: authenticating, child: UnderlinedTextButton(
              text: 'Forgot your password?',
              onTap: () async => await _navigation.navigateTo(RequestPasswordResetScreen.id))))
    ];
  }

  Widget _buildNextSenseAuth(BuildContext context, SignInScreenViewModel viewModel) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoundedBackground(
              child: Column(children: [
                _UserPasswordSignInInputField(
                    field: viewModel.username,
                    labelText: 'Id',
                    helperText: 'Please contact NextSense support if you did not get an id'),
                _UserPasswordSignInInputField(
                    field: viewModel.password,
                    obscureText: true,
                    labelText: 'Password',
                    helperText: 'Contact NextSense to reset your password'),
              ])),
          const SizedBox(height: 20),
          AbsorbPointer(absorbing: authenticating, child:
          SimpleButton(
              text: const MediumText(text: 'Login', color: NextSenseColors.darkBlue),
              onTap: authenticating ? () => {} :
                  () => _signIn(context, AuthMethod.user_code))
          )
        ]);
  }

  Widget _buildGoogleAuth(BuildContext context, SignInScreenViewModel viewModel) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AbsorbPointer(absorbing: authenticating,
        child: SignInButton(
          Buttons.Google,
          onPressed: () {
            if (!authenticating) {
              _signIn(context, AuthMethod.google_auth);
            }
          },
        ),
      )
    ]);
  }

  List<Widget> _buildBody(BuildContext context) {
    final viewModel = context.watch<SignInScreenViewModel>();

    List<Widget> signInWidgets = [];

    for (AuthMethod authMethod in viewModel.authMethods) {
      switch (authMethod) {
        case AuthMethod.email_password:
          signInWidgets.addAll(_buildEmailPasswordAuth(context, viewModel));
          break;
        case AuthMethod.user_code:
          signInWidgets.add(_buildNextSenseAuth(context, viewModel));
          break;
        case AuthMethod.google_auth:
          signInWidgets.add(_buildGoogleAuth(context, viewModel));
          break;
      }
    }

    signInWidgets.addAll([
      Visibility(
          visible: viewModel.errorMsg.isNotEmpty,
          child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: EmphasizedText(
                    text: viewModel.errorMsg, color: NextSenseColors.red, textAlign: TextAlign.center),
              ))),
      const SizedBox(height: 20),
      Visibility(
        visible: viewModel.isBusy,
        child: const CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    ]);

    // Show an error popup if needed.
    if (viewModel.errorMsg.isNotEmpty && viewModel.popupErrorMsg) {
      viewModel.popupErrorMsg = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
            context: context,
            builder: (_) => SimpleAlertDialog(
                title: 'Error',
                content: viewModel.errorMsg));
      });
    }

    return signInWidgets;
  }

  Future _signIn(BuildContext context, AuthMethod authMethod) async {
    final viewModel = context.read<SignInScreenViewModel>();
    authenticating = true;
    AuthenticationResult authResult = await viewModel.signIn(authMethod);

    if (authResult != AuthenticationResult.success) {
      authenticating = false;
      String dialogTitle, dialogContent;
      switch (authResult) {
        case AuthenticationResult.user_fetch_failed:
        case AuthenticationResult.invalid_user_setup:
        case AuthenticationResult.invalid_username_or_password:
          dialogTitle = 'Invalid email or password';
          dialogContent = 'The email is incorrect or you entered a wrong password';
          break;
        case AuthenticationResult.connection_error:
          dialogTitle = 'Connection error';
          dialogContent = 'An internet connection is needed to validate your password.';
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
      await _navigation.navigateTo(SetPasswordScreen.id, nextRoute: NavigationRoute(pop: true),
          arguments: true);
    }

    bool studyLoaded = await viewModel.loadCurrentStudy();
    if (!studyLoaded) {
      authenticating = false;
      // Cannot proceed without study data.
      await showDialog(
          context: context,
          builder: (_) => SimpleAlertDialog(
              title: 'Error with your account',
              content: 'Please contact NextSense support and mention that there is an issue with '
                  'your account study setup.'));
      return;
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
    authenticating = false;
  }
}

class _UserPasswordSignInInputField extends StatelessWidget {
  final ValueNotifier field;
  final String labelText;
  final String? helperText;
  final bool? obscureText;
  final int? maxLength;

  const _UserPasswordSignInInputField(
      {Key? key,
        required this.field,
        required this.labelText,
        this.helperText,
        this.obscureText,
        this.maxLength = EmailAuthManager.maxPasswordLength})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(10.0),
        child: TextFormField(
          cursorColor: TextSelectionTheme.of(context).cursorColor,
          initialValue: field.value,
          maxLength: maxLength,
          obscureText: obscureText ?? false,
          //enabled: !_askForPassword,
          decoration: InputDecoration(
            label: HeaderText(text: labelText, color: NextSenseColors.darkBlue),
            helperText: helperText,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6200EE)),
            ),
          ),
          onChanged: (newValue) {
            field.value = newValue;
          },
        ));
  }
}
