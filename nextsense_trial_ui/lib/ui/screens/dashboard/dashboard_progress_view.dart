import 'package:flutter/widgets.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/nextsense_app_bar.dart';
import 'package:nextsense_trial_ui/ui/components/page_container.dart';

class DashboardProgressView extends StatelessWidget {
  const DashboardProgressView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> contents = [
      NextSenseAppBar(),
      HeaderText(text: 'My Progress'),
      SizedBox(height: 15),
    ];

    return PageContainer(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: contents));
  }
}