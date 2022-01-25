import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/ui/components/SessionPopScope.dart';
import 'package:nextsense_trial_ui/ui/device_scan_screen.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/session_screen.dart';
import 'package:nextsense_trial_ui/ui/sign_in_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  final AuthManager _authManager = GetIt.instance.get<AuthManager>();
  final DeviceManager _deviceManager = GetIt.instance.get<DeviceManager>();

  Widget _buildBody(BuildContext context) {
    Widget recordSessionButton = Padding(
        padding: EdgeInsets.all(10.0),
        child: ElevatedButton(
          child: const Text('Record a session'),
          onPressed: () async {
            // Navigate to the session screen.
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SessionScreen()),
            );
          },
        ));
    Widget findDeviceButton = Padding(
        padding: EdgeInsets.all(10.0),
        child: ElevatedButton(
          child: const Text('Connect your device'),
          onPressed: () async {
            // Navigate to the device scan screen.
            await Navigation.navigateToDeviceScan(
                context, /*replaceCurrent=*/false);
            setState(() {});
          },
        ));
    Widget disconnectButton = Padding(
        padding: EdgeInsets.all(10.0),
        child: ElevatedButton(
          child: const Text('Disconnect'),
          onPressed: () async {
            _deviceManager.disconnectDevice();
            setState(() {});
            // Navigate to the device scan screen.
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DeviceScanScreen()),
            );
          },
        ));
    Widget logoutButton = Padding(
        padding: EdgeInsets.all(10.0),
        child: ElevatedButton(
          child: const Text('Logout'),
          onPressed: () async {
            _deviceManager.disconnectDevice();
            _authManager.signOut();
            // Navigate to the sign-in screen.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SignInScreen()),
            );
          },
        ));
    List<Widget> buttons = [];
    if (_deviceManager.getConnectedDevice() != null) {
      buttons.add(recordSessionButton);
      buttons.add(disconnectButton);
    } else {
      buttons.add(findDeviceButton);
    }
    buttons.add(logoutButton);
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons);
  }

  @override
  Widget build(BuildContext context) {
    return SessionPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: Text('Dashboard'),
          ),
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(child: _buildBody(context)),
          ),
        ));
  }
}