import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';

class SetPasswordScreen extends StatefulWidget {
  @override
  _SetPasswordScreenState createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final AuthManager _authManager = GetIt.instance.get<AuthManager>();
  String? _password;
  String? _passwordConfirmation;

  Future _showError(BuildContext context, String message) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleAlertDialog(title: 'Error', content: message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Set Password"),
        ),
        body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text("Set Password",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          fontFamily: 'Roboto')),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: TextFormField(
                    cursorColor: Theme.of(context).cursorColor,
                    initialValue: '',
                    maxLength: 20,
                    decoration: InputDecoration(
                      icon: Icon(Icons.password),
                      labelText: 'Enter your password',
                      labelStyle: TextStyle(
                        color: Color(0xFF6200EE),
                      ),
                      helperText: 'Minimum ${AuthManager.minimumPasswordLength} characters.',
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF6200EE)),
                      ),
                    ),
                    onChanged: (password) {
                      setState(() {
                        _password = password;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: TextFormField(
                    cursorColor: Theme.of(context).cursorColor,
                    initialValue: '',
                    maxLength: 20,
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
                      setState(() {
                        _passwordConfirmation = passwordConfirmation;
                      });
                    },
                  ),
                ),
                Padding(
                    padding: EdgeInsets.all(10.0),
                    child: TextButton(
                        child: Text('Submit'),
                        onPressed: () async {
                          if (_password == null || _password!.isEmpty) {
                            return;
                          }
                          if (_password!.length < AuthManager.minimumPasswordLength) {
                            _showError(context, 'Password should be at least '
                                '${AuthManager.minimumPasswordLength} '
                                'characters long');
                            return;
                          }
                          if (_password!.compareTo(_passwordConfirmation!) != 0) {
                            _showError(context, 'Passwords do not match.');
                            return;
                          }
                          _authManager.setPassword(_password!);
                        },
                    )),
              ]),
        ));
  }
}
