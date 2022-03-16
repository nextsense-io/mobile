import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class CheckWifiScreen extends HookWidget {

  static const String id = 'check_wifi_screen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check Wifi'),
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

                ]
          )
        ),
      ),
    );
  }
}