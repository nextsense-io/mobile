import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthManager _authManager = AuthManager();
  String _code = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("title"),
        ),
        body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text("NextSense Trial",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          fontFamily: 'Roboto')),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: TextFormField(
                    cursorColor: Theme.of(context).cursorColor,
                    initialValue: 'id',
                    maxLength: 20,
                    decoration: InputDecoration(
                      icon: Icon(Icons.account_circle),
                      labelText: 'Enter your id',
                      labelStyle: TextStyle(
                        color: Color(0xFF6200EE),
                      ),
                      helperText:
                          'Please contact NextSense support if you did not get an id',
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF6200EE)),
                      ),
                    ),
                    onChanged: (code) {
                      setState(() {
                        _code = code;
                      });
                    },
                  ),
                ),
                Padding(
                    padding: EdgeInsets.all(10.0),
                    child: SignInButton(
                      Buttons.Email,
                      text: 'Continue',
                      onPressed: () async {
                        UserCodeValidationResult result =
                            await _authManager.validateUserCode(_code);
                        if (result ==
                            UserCodeValidationResult.password_not_set) {
                          // navigate to password set screen.
                        }
                        if (result == UserCodeValidationResult.invalid) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return SimpleAlertDialog(title: 'Invalid code',
                                  content: 'The code you entered does not exists.');
                            },
                          );
                        }
                        // navigate to password screen
                      },
                    )),
              ]),
        ));
  }
}
