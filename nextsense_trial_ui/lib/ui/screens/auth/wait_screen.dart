import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/session_pop_scope.dart';
import 'package:nextsense_trial_ui/ui/components/wait_widget.dart';

class WaitScreen extends HookWidget {
  static const String id = 'wait_screen';

  @override
  Widget build(BuildContext context) {
    return SessionPopScope(
            child: PageScaffold(
                showBackButton: false,
                showProfileButton: false,
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Spacer(),
                  WaitWidget(message: 'Please wait'),
                  Spacer()
                ])));
  }
}