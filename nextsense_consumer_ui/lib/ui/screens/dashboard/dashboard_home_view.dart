import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_common/ui/components/clickable_zone.dart';
import 'package:flutter_common/ui/components/rounded_background.dart';
import 'package:nextsense_consumer_ui/ui/components/card_title_text.dart';
import 'package:nextsense_consumer_ui/ui/components/content_text.dart';
import 'package:nextsense_consumer_ui/ui/components/header_text.dart';
import 'package:nextsense_consumer_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_consumer_ui/ui/components/wait_widget.dart';
import 'package:nextsense_consumer_ui/ui/dialogs/start_adhoc_protocol_dialog.dart';
import 'package:nextsense_consumer_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:provider/provider.dart';

class DashboardHomeView extends StatelessWidget {
  const DashboardHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboardViewModel = context.watch<DashboardScreenViewModel>();

    if (dashboardViewModel.isBusy) {
      return WaitWidget(
          message: 'Loading your data.\nPlease wait...',
          textVisible: !dashboardViewModel.dataInitialized);
    }

    List<Widget> menuCards = [];
    menuCards.add(MenuCard(
        title: 'Protocols',
        image:
            SvgPicture.asset('packages/nextsense_trial_ui/assets/images/tasks.svg',
                semanticsLabel: 'Protocols', height: 75),
        onTap: () async =>
            {await showDialog(context: context, builder: (_) => StartAdhocProtocolDialog())}));

    List<Row> menuCardRows = [];
    for (int i = 0; i < menuCards.length; ++i) {
      if (i != 0) {
        menuCardRows.add(const Row(children: [SizedBox(height: 20, width: 20)]));
      }
      if (menuCards.length > i + 1) {
        menuCardRows.add(Row(children: [
          Expanded(child: Padding(padding: const EdgeInsets.only(right: 20), child: menuCards[i])),
          const SizedBox(height: 20, width: 20),
          Expanded(child: Padding(padding: const EdgeInsets.only(right: 20), child: menuCards[i + 1])),
        ]));
        ++i;
      } else {
        menuCardRows.add(Row(children: [
          Expanded(child: Padding(padding: const EdgeInsets.only(right: 20), child: menuCards[i])),
          const SizedBox(height: 20, width: 20),
          const Spacer(),
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
            const HeaderText(text: "Consumer sleep test application", marginLeft: 10),
            const SizedBox(height: 10),
            const Padding(
                padding: EdgeInsets.only(right: 20),
                child: RoundedBackground(
                    child: ContentText(text:
                    "This application is designed to run recordings and show sleep metrics."))),
            const SizedBox(height: 30),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: menuCardRows),
            const SizedBox(height: 10),
          ],
        )));
    return PageScaffold(
        viewModel: dashboardViewModel, showBackButton: false, padBottom: false, child: elements);
  }
}

class MenuCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final Widget image;

  const MenuCard({super.key, required this.title, required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final column = Column(children: [
      Align(alignment: Alignment.centerLeft, child: CardTitleText(text: title)),
      Container(
          padding: const EdgeInsets.only(top: 5),
          child: Align(alignment: Alignment.bottomRight, child: image))
    ]);
    return ClickableZone(
      onTap: onTap,
      child: RoundedBackground(child: column),
    );
  }
}
