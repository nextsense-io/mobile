import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/permissions_manager.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/prepare_device_screen.dart';
import 'package:nextsense_trial_ui/ui/request_permission_screen.dart';
import 'package:nextsense_trial_ui/ui/set_password_screen.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthManager _authManager = GetIt.instance.get<AuthManager>();
  final PermissionsManager _permissionsManager =
      GetIt.instance.get<PermissionsManager>();

  String _code = '';
  String _password = '';
  bool _askForPassword = false;

  _validatedUserCode() async {
    UserCodeValidationResult result =
        await _authManager.validateUserCode(_code);
    if (result == UserCodeValidationResult.password_not_set) {
      // navigate to password set screen.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SetPasswordScreen()),
      );
      return;
    }
    if (result == UserCodeValidationResult.invalid) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleAlertDialog(
              title: 'Invalid code',
              content: 'The code you entered does not exists.');
        },
      );
      return;
    }

    // Ask the user to enter his password.
    setState(() {
      _askForPassword = true;
    });
  }

  _signIn() async {
    bool authenticated = await _authManager.signIn(_password);
    if (!authenticated) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleAlertDialog(
              title: 'Invalid password',
              content: 'The password you entered is invalid.');
        },
      );
      return;
    }

    // If there are permissions that need to be granted, go through them one by
    // one with an explanation screen.
    for (PermissionRequest permissionRequest
    in await _permissionsManager.getPermissionsToRequest()) {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RequestPermissionScreen(permissionRequest)),
      );
    }
    // Navigate to the device preparation screen.
    // TODO(eric): Might want to add a 'Do not show this again' in that page and
    // check first before going to that page.
    // TODO(eric): Might want to pop back with a true/false result at this point
    // to remove the login page from the stack?
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrepareDeviceScreen()),
    );
  }

  List<Widget> _buildBody(BuildContext context) {
    List<Widget> widgets = <Widget>[
      Padding(
        padding: EdgeInsets.all(10.0),
        child: Text('NextSense Trial',
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
          enabled: !_askForPassword,
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
    ];
    if (_askForPassword) {
      widgets.add(
        Padding(
          padding: EdgeInsets.all(10.0),
          child: TextFormField(
            cursorColor: TextSelectionTheme.of(context).cursorColor,
            initialValue: '',
            maxLength: 20,
            decoration: InputDecoration(
              icon: Icon(Icons.account_circle),
              labelText: 'Enter your password',
              labelStyle: TextStyle(
                color: Color(0xFF6200EE),
              ),
              helperText:
              'Contact NextSense to reset your password',
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
      );
    }
    widgets.add(Padding(
        padding: EdgeInsets.all(10.0),
        child: ElevatedButton(
          child: const Text('Continue'),
          onPressed: () async {
            if (_askForPassword) {
              _signIn();
            } else {
              _validatedUserCode();
            }
          },
        )));
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
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
                children: _buildBody(context),
            ),
        ),
      ),
    );
  }
}
