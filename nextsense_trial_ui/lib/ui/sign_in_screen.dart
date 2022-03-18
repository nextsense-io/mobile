import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/permissions_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/ui/components/background_decoration.dart';
import 'package:nextsense_trial_ui/ui/components/session_pop_scope.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen.dart';
import 'package:nextsense_trial_ui/ui/prepare_device_screen.dart';
import 'package:nextsense_trial_ui/ui/request_permission_screen.dart';
import 'package:nextsense_trial_ui/ui/set_password_screen.dart';

class SignInScreen extends StatefulWidget {

  static const String id = 'sign_in_screen';

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthManager _authManager = getIt<AuthManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final Navigation _navigation = getIt<Navigation>();
  final PermissionsManager _permissionsManager = getIt<PermissionsManager>();

  // Change _code and _password to some values and _askForPassword to true
  // for autologin
  String _code = 'eemu_001';
  String _password = 'nextsense';
  bool _askForPassword = true;

  @override
  void initState()  {
    super.initState();

    // Do autologin to save time when debugging
    if (_code.isNotEmpty && _password.isNotEmpty) {
        void _autologin() async {
          await _validatedUserCode();
          await _signIn();
        }
        _autologin();
    };
  }


  @override
  Widget build(BuildContext context) {
    return SessionPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: Text('Login'),
          ),
          body: Container(
            decoration: baseBackgroundDecoration,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildBody(context),
              ),
            ),
          ),
        ));
  }

  _validatedUserCode() async {
    UserCodeValidationResult result =
        await _authManager.validateUserCode(_code);
    if (result == UserCodeValidationResult.password_not_set) {
      // navigate to password set screen.
      _navigation.navigateTo(SetPasswordScreen.id);
      return;
    }
    if (result == UserCodeValidationResult.invalid) {
      await showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
              title: 'Invalid code',
              content: 'The code you entered does not exists.')
      );
      return;
    }
    if (result == UserCodeValidationResult.no_connection) {
      await showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
              title: 'No connection',
              content: 'An internet connection is needed to validate your user '
                  'code.')
      );
      return;
    }

    // Ask the user to enter his password.
    setState(() {
      _askForPassword = true;
    });
  }

  Future _signIn() async {
    bool authenticated = false;
    try {
      authenticated = await _authManager.signIn(_password);
    } catch (e) {
      await showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
              title: 'Error',
              content: 'An internet connection is needed to validate your '
                  'password.')
      );
      return;
    }
    if (!authenticated) {
      await showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
              title: 'Invalid password',
              content: 'The password you entered is invalid.')
      );
      return;
    }

    // If there are permissions that need to be granted, go through them one by
    // one with an explanation screen.
    for (PermissionRequest permissionRequest
        in await _permissionsManager.getPermissionsToRequest()) {
      await _navigation.navigateTo(RequestPermissionScreen.id,
          arguments: permissionRequest);
    }

    // Load the study data.
    final userEntity = _authManager.getUserEntity()!;

    // TODO(alex): can start and end dates be null?
    bool studyLoaded = await _studyManager.loadCurrentStudy(
        userEntity.getValue(UserKey.study),
        userEntity.getStudyStartDate()!,
        userEntity.getStudyEndDate()!,
    );

    if (!studyLoaded) {
      // Cannot proceed without study data.
      await showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
              title: 'Error with your account',
              content: 'Please contact NextSense support and mention that there'
                  ' is an issue with your account study setup.')
      );
      return;
    }

    // Navigate to the device preparation screen.
    _navigation.navigateTo(DashboardScreen.id);
    // TODO(eric): Might want to add a 'Do not show this again' in that page and
    // check first before going to that page.
    await _navigation.navigateTo(PrepareDeviceScreen.id);
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
          initialValue: _code,
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
            initialValue: _password,
            maxLength: 20,
            obscureText: true,
            decoration: InputDecoration(
              icon: Icon(Icons.account_circle),
              labelText: 'Enter your password',
              labelStyle: TextStyle(
                color: Color(0xFF6200EE),
              ),
              helperText: 'Contact NextSense to reset your password',
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

}
