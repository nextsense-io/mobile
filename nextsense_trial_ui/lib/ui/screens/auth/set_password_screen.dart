import 'package:flutter/material.dart';
import 'package:flutter_common/managers/auth/email_auth_manager.dart';
import 'package:flutter_common/managers/auth/password_change_result.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:flutter_common/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:flutter_common/ui/components/rounded_background.dart';
import 'package:flutter_common/ui/components/session_pop_scope.dart';
import 'package:flutter_common/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/re_authenticate_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/set_password_screen_vm.dart';
import 'package:stacked/stacked.dart';

class SetPasswordScreen extends HookWidget {
  static const String id = 'set_password_screen';

  final bool isSignup;
  final _navigation = getIt<Navigation>();

  SetPasswordScreen({this.isSignup = false});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SetPasswordScreenViewModel>.reactive(
        viewModelBuilder: () => SetPasswordScreenViewModel(),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) {
          return SessionPopScope(
            child: SafeArea(
                child: PageScaffold(
                    showBackButton: _navigation.canPop(),
                    showProfileButton: false,
                    child: _buildBody(context, viewModel))),
          );
        });
  }

  Future _showDialog(BuildContext context, String title, String message, bool? popNavigator,
      Function? onPressed) async {
    showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: title,
            content: message,
            popNavigator: popNavigator != null ? popNavigator : false,
            onPressed: onPressed));
  }

  Widget _buildBody(BuildContext context, SetPasswordScreenViewModel viewModel) {
    if (viewModel.hasError) {
      Future.delayed(Duration.zero, () {
        _showDialog(context, 'Error', viewModel.modelError, false, () => {viewModel.clearErrors()});
      });
    }
    return Container(
        child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(10.0),
                child: HeaderText(text: isSignup ? 'Set your password' : 'Replace Password'),
              ),
              RoundedBackground(
                  child: Column(children: [
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: TextFormField(
                    cursorColor: TextSelectionTheme.of(context).cursorColor,
                    initialValue: '',
                    maxLength: 20,
                    obscureText: true,
                    decoration: InputDecoration(
                      // icon: Icon(Icons.password),
                      label: MediumText(text: isSignup ? 'Password' : 'New Password',
                          color: NextSenseColors.darkBlue),
                      helperText: 'Minimum ${viewModel.minimumPasswordLength} characters.',
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF6200EE)),
                      ),
                    ),
                    onChanged: (password) {
                      viewModel.password = password;
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: TextFormField(
                    cursorColor: TextSelectionTheme.of(context).cursorColor,
                    initialValue: '',
                    maxLength: EmailAuthManager.maxPasswordLength,
                    obscureText: true,
                    decoration: InputDecoration(
                      // icon: Icon(Icons.password),
                      label: MediumText(
                          text: 'Confirm your password', color: NextSenseColors.darkBlue),
                      helperText: '',
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF6200EE)),
                      ),
                    ),
                    onChanged: (passwordConfirmation) {
                      viewModel.passwordConfirmation = passwordConfirmation;
                    },
                  ),
                ),
              ])),
              SizedBox(height: 20),
              SimpleButton(
                text: MediumText(
                  text: isSignup ? 'Set Password' : 'Replace Password',
                  color: NextSenseColors.purple,
                  textAlign: TextAlign.center,
                ),
                onTap: viewModel.isBusy
                    ? () => {print('busy cannot submit')}
                    : () => _onSubmitButtonPressed(context, viewModel),
              ),
            ]),
        SizedBox(height: 20),
        Visibility(
          visible: viewModel.isBusy,
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      ],
    )));
  }

  Future<void> _onSubmitButtonPressed(
      BuildContext context, SetPasswordScreenViewModel viewModel) async {
    PasswordChangeResult result = await viewModel.changePassword();
    switch (result) {
      case PasswordChangeResult.success:
        await _showDialog(
            context, isSignup ? 'Password set' : 'Password changed', '', false,
                () => _navigation.navigateToNextRoute());
        break;
      case PasswordChangeResult.invalid_password:
        await _showDialog(context, 'Error', 'Invalid password', false, null);
        break;
      case PasswordChangeResult.need_reauthentication:
        await _showDialog(
            context,
            'Verify your password',
            'You need to authenticate again before you can change your password',
            false,
            () => _navigation.navigateTo(ReAuthenticateScreen.id));
        break;
      case PasswordChangeResult.error:
      case PasswordChangeResult.connection_error:
        // Error is displayed in the UI already.
        break;
    }
  }
}
