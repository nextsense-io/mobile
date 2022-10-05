import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/rounded_background.dart';
import 'package:nextsense_trial_ui/ui/components/session_pop_scope.dart';
import 'package:nextsense_trial_ui/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/set_password_screen_vm.dart';
import 'package:stacked/stacked.dart';

class SetPasswordScreen extends HookWidget {
  static const String id = 'set_password_screen';

  final _navigation = getIt<Navigation>();

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
                    child: _buildBody(context, viewModel)
                )
            ),
          );
        });
  }

  Future _showDialog(BuildContext context, String title, String message, bool? popNavigator,
      Function? onPressed) async {
    showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
          title: title, content: message, popNavigator: popNavigator != null ? popNavigator : false,
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
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10.0),
              child: HeaderText(text: 'Replace Password'),
            ),
            RoundedBackground(child: Column(children: [
            Padding(
              padding: EdgeInsets.all(10.0),
              child: TextFormField(
                cursorColor: TextSelectionTheme.of(context).cursorColor,
                initialValue: '',
                maxLength: 20,
                obscureText: true,
                decoration: InputDecoration(
                  // icon: Icon(Icons.password),
                  label: MediumText(text: 'New Password', color: NextSenseColors.darkBlue),
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
                maxLength: 20,
                obscureText: true,
                decoration: InputDecoration(
                  // icon: Icon(Icons.password),
                  label: MediumText(text: 'Confirm your password', color: NextSenseColors.darkBlue),
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
                  text: MediumText(text: 'Replace Password', color: NextSenseColors.purple,
                    textAlign: TextAlign.center,),
                  onTap: viewModel.isBusy ? () => {print('busy cannot submit')} :
                      () => _onSubmitButtonPressed(context, viewModel),
                ),
            Visibility(
              visible: viewModel.isBusy,
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ]),
        ));
  }

  Future<void> _onSubmitButtonPressed(BuildContext context,
      SetPasswordScreenViewModel viewModel) async {
    try {
      bool passwordChanged = await viewModel.changePassword();
      if (passwordChanged) {
        await _showDialog(context, 'Password changed', '', false,
                () => _navigation.navigateToNextRoute());
      } else {
        await _showDialog(context, 'Error', 'Invalid password', false, null);
      }
    } catch (e) {
      _showDialog(
          context,
          'Error',
          'Could not set password, make sure you have an active internet connection and try again.',
          false, null);
      return;
    }
  }
}
