import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SupportScreen extends HookWidget {

  static const String id = 'support_screen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(child: Text("Support")),
      ),
    );
  }
}