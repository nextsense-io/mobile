import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/prepare_device_screen.dart';
import 'package:nextsense_trial_ui/ui/set_password_screen.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthManager _authManager = GetIt.instance.get<AuthManager>();
  String _code = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
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
                    initialValue: '',
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
                    child: ElevatedButton(
                      child: const Text('Continue'),
                      onPressed: () async {
                        UserCodeValidationResult result =
                            await _authManager.validateUserCode(_code);
                        if (result ==
                            UserCodeValidationResult.password_not_set) {
                          // navigate to password set screen.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SetPasswordScreen()),
                          );
                        }
                        if (result == UserCodeValidationResult.invalid) {
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return SimpleAlertDialog(
                                  title: 'Invalid code',
                                  content:
                                      'The code you entered does not exists.');
                            },
                          );
                        }
                        // navigate to device preparation screen.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PrepareDeviceScreen()),
                        );
                      },
                    )),
              ]),
        ),
      ),
    );
  }
}
