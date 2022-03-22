import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/ui/components/background_decoration.dart';

class SupportScreen extends HookWidget {

  static const String id = 'support_screen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Support'),
      ),
      body: Container(
        decoration: baseBackgroundDecoration,
      ),
    );
  }
}