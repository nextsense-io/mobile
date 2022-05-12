import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/background_decoration.dart';
import 'package:nextsense_trial_ui/ui/components/session_pop_scope.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/set_password_screen_vm.dart';
import 'package:stacked/stacked.dart';

class SetPasswordScreen extends HookWidget {
  static const String id = 'set_password_screen';

  final _navigation = getIt<Navigation>();

  String _password = "";
  String _passwordConfirmation = "";

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SetPasswordScreenViewModel>.reactive(
        viewModelBuilder: () => SetPasswordScreenViewModel(),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) {
          return SessionPopScope(
            child: SafeArea(
                child: Scaffold(
                    appBar: AppBar(
                      title: Text('Change password'),
                    ),
                    body: _buildBody(context, viewModel)
                )
            ),
          );
        });
  }

  Future _showDialog(BuildContext context, String title, String message, bool popNavigator,
      Function? onPressed) async {
    showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
          title: title, content: message, popNavigator: popNavigator, onPressed: onPressed));
  }

  Widget _buildBody(BuildContext context, SetPasswordScreenViewModel viewModel) {
    return Container(
        decoration: baseBackgroundDecoration,
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Text('Change Password',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 30, fontFamily: 'Roboto')),
            ),
            Padding(
              padding: EdgeInsets.all(10.0),
              child: TextFormField(
                cursorColor: TextSelectionTheme.of(context).cursorColor,
                initialValue: '',
                maxLength: 20,
                obscureText: true,
                decoration: InputDecoration(
                  icon: Icon(Icons.password),
                  labelText: 'Enter your password',
                  labelStyle: TextStyle(
                    color: Color(0xFF6200EE),
                  ),
                  helperText: 'Minimum ${viewModel.minimumPasswordLength} characters.',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6200EE)),
                  ),
                ),
                onChanged: (password) {
                  _password = password;
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
                  icon: Icon(Icons.password),
                  labelText: 'Confirm your password',
                  labelStyle: TextStyle(
                    color: Color(0xFF6200EE),
                  ),
                  helperText: '',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6200EE)),
                  ),
                ),
                onChanged: (passwordConfirmation) {
                  _passwordConfirmation = passwordConfirmation;
                },
              ),
            ),
            Padding(
                padding: EdgeInsets.all(10.0),
                child: TextButton(
                  child: Text('Submit'),
                  onPressed: viewModel.isBusy ? () => {} :
                      () => _onSubmitButtonPressed(context, viewModel),
                )),
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
    final String password = _password;
    if (password.isEmpty) {
      return;
    }
    if (password.length < viewModel.minimumPasswordLength) {
      _showDialog(
          context,
          'Error',
          'Password should be at least ${viewModel.minimumPasswordLength} characters long',
          false, null);
      return;
    }
    if (password.compareTo(_passwordConfirmation) != 0) {
      _showDialog(context, 'Error', 'Passwords do not match.', false, null);
      return;
    }
    try {
      bool passwordChanged = await viewModel.changePassword(password);
      if (passwordChanged) {
        await _showDialog(context, 'Password Set', 'Please login again to access the system.',
            false, () => _navigation.signOut());
        return;
      } else {
        _showDialog(
            context,
            'Error',
            'Could not set password, make sure you have an active internet connection and try '
                'again.',
            false, null);
        return;
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
