import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/flavors.dart';
import 'package:nextsense_trial_ui/ui/components/card_title_text.dart';
import 'package:flutter_common/ui/components/clickable_zone.dart';
import 'package:nextsense_trial_ui/ui/components/content_text.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/rounded_background.dart';
import 'package:nextsense_trial_ui/ui/components/thick_content_text.dart';
import 'package:nextsense_trial_ui/ui/components/wait_widget.dart';
import 'package:nextsense_trial_ui/ui/dialogs/start_adhoc_protocol_dialog.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/surveys_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/medications/medications_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/seizures/seizures_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/side_effects/side_effects_screen.dart';
import 'package:provider/provider.dart';

class DashboardHomeView extends StatelessWidget {
  final Navigation _navigation = getIt<Navigation>();
  final Flavor _flavor = getIt<Flavor>();

  DashboardHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboardViewModel = context.watch<DashboardScreenViewModel>();

    if (dashboardViewModel.isBusy) {
      var loadingTextVisible =
          dashboardViewModel.studyInitialized != null && !dashboardViewModel.studyInitialized!;
      return WaitWidget(
          message: 'Your study is initializing.\nPlease wait...', textVisible: loadingTextVisible);
    }

    String studyStatusHeader;
    String studyStatusContent;
    if (!dashboardViewModel.studyStarted) {
      studyStatusHeader = 'Study not started';
      studyStatusContent = '';
    } else if (dashboardViewModel.studyFinished) {
      studyStatusHeader = 'Study\nfinished';
      studyStatusContent = '';
    } else if (dashboardViewModel.studyLengthDays == '0') {
      studyStatusHeader = 'Ongoing\nstudy';
      studyStatusContent = '';
    } else {
      studyStatusHeader = '${dashboardViewModel.today?.dayNumber.toString() ?? '0'}'
          '/${dashboardViewModel.studyLengthDays}';
      studyStatusContent = 'days in study';
    }

    final daysInStudy = Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      HeaderText(text: studyStatusHeader),
      ThickContentText(text: studyStatusContent),
    ]);
    final completedSurveys = Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      HeaderText(text: dashboardViewModel.completedSurveys),
      ThickContentText(text: 'completed surveys'),
    ]);
    final studySummaryRow = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: daysInStudy),
      SizedBox(height: 20, width: 20),
      Expanded(child: completedSurveys),
    ]);

    List<Widget> menuCards = [];
    if (_flavor.userType == UserType.researcher && dashboardViewModel.studyHasAdhocProtocols) {
      menuCards.add(MenuCard(
          title: 'Protocols',
          image:
              SvgPicture.asset('packages/nextsense_trial_ui/assets/images/tasks.svg', semanticsLabel: 'Protocols', height: 75),
          onTap: () async =>
              {await showDialog(context: context, builder: (_) => StartAdhocProtocolDialog())}));
    }
    if (dashboardViewModel.study.seizureTrackingEnabled) {
      menuCards.add(MenuCard(
          title: 'Seizures',
          image:
              SvgPicture.asset('packages/nextsense_trial_ui/assets/images/brain.svg', semanticsLabel: 'Seizures', height: 75),
          onTap: () => _navigation.navigateTo(SeizuresScreen.id)));
    }
    if (dashboardViewModel.study.medicationTrackingEnabled) {
      menuCards.add(MenuCard(
          title: 'Medications',
          image:
              SvgPicture.asset('packages/nextsense_trial_ui/assets/images/pill.svg', semanticsLabel: 'Medications', height: 75),
          onTap: () => _navigation.navigateTo(MedicationsScreen.id)));
    }
    if (dashboardViewModel.study.sideEffectsTrackingEnabled) {
      menuCards.add(MenuCard(
          title: 'Side Effects',
          image: SvgPicture.asset('packages/nextsense_trial_ui/assets/images/head.svg',
              semanticsLabel: 'Side Effects', height: 75),
          onTap: () => _navigation.navigateTo(SideEffectsScreen.id)));
    }
    if (dashboardViewModel.scheduledSurveys.isNotEmpty) {
      menuCards.add(MenuCard(
          title: 'Surveys',
          image: SvgPicture.asset('packages/nextsense_trial_ui/assets/images/tasks.svg', semanticsLabel: 'Surveys', height: 75),
          onTap: () => _navigation.navigateTo(SurveysScreen.id)));
    }

    List<Row> menuCardRows = [];
    for (int i = 0; i < menuCards.length; ++i) {
      if (i != 0) {
        menuCardRows.add(Row(children: [SizedBox(height: 20, width: 20)]));
      }
      if (menuCards.length > i + 1) {
        menuCardRows.add(Row(children: [
          Expanded(child: Padding(padding: EdgeInsets.only(right: 20), child: menuCards[i])),
          SizedBox(height: 20, width: 20),
          Expanded(child: Padding(padding: EdgeInsets.only(right: 20), child: menuCards[i + 1])),
        ]));
        ++i;
      } else {
        menuCardRows.add(Row(children: [
          Expanded(child: Padding(padding: EdgeInsets.only(right: 20), child: menuCards[i])),
          SizedBox(height: 20, width: 20),
          Spacer(),
        ]));
      }
    }

    final elements = Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeaderText(text: dashboardViewModel.studyName, marginLeft: 10),
            SizedBox(height: 10),
            Padding(
                padding: EdgeInsets.only(right: 20),
                child: RoundedBackground(
                    child: ContentText(text: dashboardViewModel.studyDescription))),
            SizedBox(height: 30),
            studySummaryRow,
            SizedBox(height: 30),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: menuCardRows),
            SizedBox(height: 10),
          ],
        )));
    return PageScaffold(
        viewModel: dashboardViewModel, showBackButton: false, padBottom: false, child: elements);
  }
}

class MenuCard extends StatelessWidget {
  final Function onTap;
  final String title;
  final Widget image;

  MenuCard({required this.title, required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final column = Column(children: [
      Align(alignment: Alignment.centerLeft, child: CardTitleText(text: title)),
      Container(
          padding: EdgeInsets.only(top: 5),
          child: Align(alignment: Alignment.bottomRight, child: image))
    ]);
    return ClickableZone(
      onTap: onTap,
      child: RoundedBackground(child: column),
    );
  }
}
