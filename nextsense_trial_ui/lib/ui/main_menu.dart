import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class MainMenu extends HookWidget {

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.power_off),
            label: Text('Disconnect'),
              onPressed: () {
                  // TOD
              }
          ),
          _MainMenuItem(
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              onPressed: () {

              }
          ),
          _MainMenuItem(
              icon: Icon(Icons.help),
              label: Text('Help'),
              onPressed: () {

              }
          ),
          _MainMenuItem(
              icon: Icon(Icons.contact_support_outlined),
              label: Text('Support'),
              onPressed: () {

              }
          ),
          _MainMenuItem(
              icon: Icon(Icons.info_outlined),
              label: Text('About'),
              onPressed: () {

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
