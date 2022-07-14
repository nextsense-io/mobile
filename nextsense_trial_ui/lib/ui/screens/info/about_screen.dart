import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/components/emphasized_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';

class AboutScreen extends HookWidget {

  static const String id = 'about_screen';

  final Navigation _navigation = getIt<Navigation>();

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
        showProfileButton: false,
        showBackButton: false,
        showCancelButton: false,
        backButtonCallback: () => _navigation.pop(),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Spacer(),
              EmphasizedText(text: 'About', textAlign: TextAlign.center),
              Spacer(),
            ]));
  }
}