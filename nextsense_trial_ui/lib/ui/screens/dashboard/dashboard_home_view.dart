import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/components/card_title_text.dart';
import 'package:nextsense_trial_ui/ui/components/clickable_zone.dart';
import 'package:nextsense_trial_ui/ui/components/content_text.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/nextsense_app_bar.dart';
import 'package:nextsense_trial_ui/ui/components/page_container.dart';
import 'package:nextsense_trial_ui/ui/components/rounded_background.dart';
import 'package:nextsense_trial_ui/ui/components/wait_widget.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/seizures/seizures_screen.dart';
import 'package:provider/provider.dart';

class DashboardHomeView extends StatelessWidget {

  final Navigation _navigation = getIt<Navigation>();

  DashboardHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboardViewModel = context.watch<DashboardScreenViewModel>();

    if (dashboardViewModel.isBusy) {
      var loadingTextVisible =
          dashboardViewModel.studyInitialized != null && !dashboardViewModel.studyInitialized!;
      return WaitWidget(message: 'Your study is initializing.\nPlease wait...',
          textVisible: loadingTextVisible);
    }

    String studyStatusHeader;
    String studyStatusContent;
    if (!dashboardViewModel.studyStarted) {
      studyStatusHeader = 'Study not started';
      studyStatusContent = '';
    } else if (dashboardViewModel.studyFinished) {
      studyStatusHeader = 'Study\nfinished';
      studyStatusContent = '';
    } else {
      studyStatusHeader = (dashboardViewModel.today?.dayNumber.toString() ?? '0') + '/' +
          dashboardViewModel.studyLengthDays;
      studyStatusContent = 'days in study';
    }

    final daysInStudy = Column(children: [
      HeaderText(text: studyStatusHeader),
      ContentText(text: studyStatusContent),
    ]);
    final completedSurveys = Column(children: [
      HeaderText(text: dashboardViewModel.completedSurveys),
      ContentText(text: 'completed surveys'),
    ]);
    final studySummaryRow = Row(children: [
      Spacer(),
      daysInStudy,
      Spacer(),
      completedSurveys,
      Spacer(),
    ]);

    final menuCards = Column(children: [
      Row(children: [
        MenuCard(title: 'Seizures',
            image: SvgPicture.asset('assets/images/brain.svg', semanticsLabel: 'Seizures',
                height: 75),
            onTap: () => _navigation.navigateTo(SeizuresScreen.id)),
        SizedBox(height: 20, width: 20),
        MenuCard(title: 'Medications',
            image: SvgPicture.asset('assets/images/pill.svg', semanticsLabel: 'Medications',
                height: 75),
            onTap: _dummy),
      ]),
      SizedBox(height: 20, width: 20),
      Row(children: [
        MenuCard(title: 'Side Effects',
            image: SvgPicture.asset('assets/images/head.svg', semanticsLabel: 'Side Effects',
                height: 75),
            onTap: _dummy),
        SizedBox(height: 20, width: 20),
        MenuCard(title: 'Surveys',
            image: SvgPicture.asset('assets/images/tasks.svg', semanticsLabel: 'Surveys',
                height: 75),
            onTap: _dummy),
      ]),
    ]
    );

    final elements = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NextSenseAppBar(),
        HeaderText(text: dashboardViewModel.studyName),
        SizedBox(height: 10),
        RoundedBackground(child: ContentText(text: dashboardViewModel.studyDescription)),
        Spacer(),
        studySummaryRow,
        Spacer(),
        menuCards,
        Spacer(),
      ],
    );
    return PageContainer(child: elements);
  }

  // TODO(eric): Use real targets when available.
  void _dummy() {}
}

class MenuCard extends StatelessWidget {
  final Function onTap;
  final String title;
  final Widget image;

  MenuCard({required this.title, required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final column = Column(children: [
      CardTitleText(text: title),
      Container(
          padding: EdgeInsets.all(5), child: Align(alignment: Alignment.bottomRight, child: image))
    ]);
    return Expanded(
        child: ClickableZone(
          onTap: onTap,
          child: RoundedBackground(child: column),
    ));
  }
}