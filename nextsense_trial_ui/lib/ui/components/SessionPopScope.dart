import 'package:flutter/material.dart';
import 'package:nextsense_base/nextsense_base.dart';

class SessionPopScope extends StatelessWidget {
  final Widget child;

  SessionPopScope({required Widget this.child}) {}

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          NextsenseBase.setFlutterActivityActive(false);
          return true;
        },
        child: child);
  }
}