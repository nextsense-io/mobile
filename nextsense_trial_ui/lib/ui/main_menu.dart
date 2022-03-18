import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/impedance_calculation_screen.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/info/about_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/info/help_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/info/support_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/settings/settings_screen.dart';
import 'package:provider/src/provider.dart';

class MainMenu extends HookWidget {

  final Navigation _navigation = getIt<Navigation>();

  @override
  Widget build(BuildContext context) {

    final dashboardViewModel = context.read<DashboardScreenViewModel>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Center(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person),
                ),
                title: Text("User Name"),
                subtitle: Text("username@gmail.com"),
              ),
            ),
          ),
          _MainMenuItem(
              icon: Icon(Icons.earbuds),
              label: Text('Check earbuds settings'),
              onPressed: () {
                _navigation.navigateTo(ImpedanceCalculationScreen.id, pop: true);
              }
          ),
          _MainMenuItem(
            icon: Icon(Icons.power_off),
            label: Text('Disconnect'),
              onPressed: () {
                dashboardViewModel.disconnectDevice();
                _navigation.navigateToDeviceScan();
              }
          ),
          _MainMenuItem(
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              onPressed: () {
                dashboardViewModel.disconnectDevice();
                _navigation.signOut();
              }
          ),
          _MainMenuItem(
              icon: Icon(Icons.help),
              label: Text('Help'),
              onPressed: () {
                _navigation.navigateTo(HelpScreen.id, pop: true);
              }
          ),
          _MainMenuItem(
              icon: Icon(Icons.settings),
              label: Text('Settings'),
              onPressed: () {
                _navigation.navigateTo(SettingsScreen.id, pop: true);
              }
          ),
          _MainMenuItem(
              icon: Icon(Icons.contact_support_outlined),
              label: Text('Support'),
              onPressed: () {
                _navigation.navigateTo(SupportScreen.id, pop: true);
              }
          ),
          _MainMenuItem(
              icon: Icon(Icons.info_outlined),
              label: Text('About'),
              onPressed: () {
                _navigation.navigateTo(AboutScreen.id, pop: true);
              }
          )
        ],
      ),
    );
  }
}


class _MainMenuItem extends StatelessWidget {
  final Widget icon;
  final Widget label;
  final VoidCallback? onPressed;

  const _MainMenuItem({
    Key? key,
    required this.icon,
    required this.label,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 14,
          bottom: 14,
          left: 24,
          right: 8,
        ),
        child: Row(
          children: <Widget>[
            icon,
            SizedBox(width: 16),
            Expanded(
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                child: label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
