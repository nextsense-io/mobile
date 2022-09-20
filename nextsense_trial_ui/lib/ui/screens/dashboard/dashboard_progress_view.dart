import 'package:flutter/widgets.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';

class DashboardProgressView extends StatelessWidget {
  const DashboardProgressView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> contents = [
      HeaderText(text: 'My Progress'),
      SizedBox(height: 15),
    ];

    return PageScaffold(
        showBackButton: false,
        padBottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: contents));
  }
}