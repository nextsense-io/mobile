import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/components/emphasized_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:flutter_common/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';

class EntryAddedScreen extends HookWidget {

  static const String id = 'entry_added_screen';

  final Navigation _navigation = getIt<Navigation>();
  final String text;
  final Image image;

  EntryAddedScreen(this.text, this.image);

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
              Center(child: image),
              SizedBox(height: 10),
              EmphasizedText(text: text, textAlign: TextAlign.center),
              Spacer(),
              SimpleButton(
                  text: Center(child: MediumText(text: 'Go to Tasks',
                      color: NextSenseColors.purple)),
                  onTap: () => Navigator.pop(context))
            ]));
  }
}