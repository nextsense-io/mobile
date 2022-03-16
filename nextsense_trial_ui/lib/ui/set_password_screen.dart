import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_it/get_it.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';

class SetPasswordScreen extends HookWidget {

  static const String id = 'set_password_screen';

  final AuthManager _authManager = getIt<AuthManager>();

  Future _showDialog(BuildContext context, String title, String message,
      bool popNavigator) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleAlertDialog(title: title, content: message,
            popNavigator: popNavigator);
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final _password = useState<String>("");
    final _passwordConfirmation = useState<String>("");

    return Scaffold(
        appBar: AppBar(
          title: Text('Set Password'),
        ),
        body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text('Set Password',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                              fontFamily: 'Roboto')),
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
                          helperText:
                              'Minimum ${AuthManager.minimumPasswordLength} characters.',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF6200EE)),
                          ),
                        ),
                        onChanged: (password) {
                          _password.value = password;
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
                            _passwordConfirmation.value = passwordConfirmation;
                        },
                      ),
                    ),
                    Padding(
                        padding: EdgeInsets.all(10.0),
                        child: TextButton(
                          child: Text('Submit'),
                          onPressed: () async {
                            final String password = _password.value;
                            if (password.isEmpty) {
                              return;
                            }
                            if (password.length <
                                AuthManager.minimumPasswordLength) {
                              _showDialog(
                                  context, 'Error',
                                  'Password should be at least '
                                  '${AuthManager.minimumPasswordLength} '
                                  'characters long', false);
                              return;
                            }
                            if (password.compareTo(_passwordConfirmation.value) !=
                                0) {
                              _showDialog(context, 'Error',
                                  'Passwords do not match.', false);
                              return;
                            }
                            try {
                              _authManager.setPassword(password);
                            } catch (e) {
                              _showDialog(context, 'Error',
                                  'Could not set password, make sure you have '
                                  'an active internet connection and try'
                                  ' again.', false);
                              return;
                            }
                            _showDialog(context, 'Password Set',
                                'Please login to access the system.', true);
                          },
                        )),
                  ]),
            )));
  }
}
