import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/seizure.dart';
import 'package:nextsense_trial_ui/domain/timed_entry.dart';
import 'package:nextsense_trial_ui/ui/components/add_floating_button.dart';
import 'package:flutter_common/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/round_background.dart';
import 'package:nextsense_trial_ui/ui/components/timed_entry_cart.dart';
import 'package:nextsense_trial_ui/ui/components/wait_widget.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/seizures/seizure_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/seizures/seizures_screen_vm.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class SeizuresScreen extends HookWidget {
  static const String id = 'seizures_screen';

  final Navigation _navigation = getIt<Navigation>();

  Future<dynamic> _editSeizure(BuildContext context, dynamic seizure) async {
    await _navigation.navigateTo(SeizureScreen.id, pop: true, arguments: seizure);
  }

  Future<dynamic> _deleteSeizure(BuildContext context, dynamic seizure) async {
    SeizuresScreenViewModel viewModel = context.read<SeizuresScreenViewModel>();
    bool deleted = await viewModel.deleteSeizure(seizure);
    if (!deleted) {
      showDialog(
          context: context,
          builder: (_) => SimpleAlertDialog(
              title: 'Error deleting',
              content: 'Please try again and contact support if you get additional errors.'));
    }
  }

  Function(BuildContext, dynamic) _getSeizureEditFunction(TimedEntry seizure) {
    return _editSeizure;
  }

  Widget getListElement(Seizure seizure) {
    return Padding(
        padding: EdgeInsets.only(right: 20),
        child: Slidable(
      child: TimedEntryCard(seizure, _getSeizureEditFunction(seizure)),
      // The end action pane is the one at the right or the bottom side.
      endActionPane: ActionPane(
        motion: ScrollMotion(),
        children: [
          CustomSlidableAction(
              backgroundColor: Colors.transparent,
              onPressed: (context) {
                _editSeizure(context, seizure);
              },
              autoClose: true,
              child: RoundBackground(
                  color: Colors.white,
                  elevation: 3,
                  width: 80,
                  height: 80,
                  onPressed: () => _getSeizureEditFunction(seizure),
                  child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Image(image: Svg('packages/nextsense_trial_ui/assets/images/pen.svg'), width: 25, height: 25)))),
          CustomSlidableAction(
              backgroundColor: Colors.transparent,
              onPressed: (context) => _deleteSeizure(context, seizure),
              autoClose: true,
              child: RoundBackground(
                  color: Colors.white,
                  elevation: 3,
                  width: 80,
                  height: 80,
                  child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Image(
                          image: Svg('packages/nextsense_trial_ui/assets/images/thrash_can.svg'), width: 25, height: 25)))),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SeizuresScreenViewModel>.reactive(
        viewModelBuilder: () => SeizuresScreenViewModel(),
        onViewModelReady: (viewModel) => viewModel.init(),
        // createNewModelOnInsert: true,
        builder: (context, SeizuresScreenViewModel viewModel, child) => PageScaffold(
            floatingActionButton: AddFloatingButton(
                onPressed: () => _navigation.navigateTo(SeizureScreen.id, pop: true)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderText(text: 'Seizures'),
                SizedBox(height: 10),
                if (viewModel.isBusy)
                  WaitWidget(message: 'Loading seizures...')
                else
                  Expanded(
                      child: Scrollbar(thumbVisibility: true, child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: viewModel.getSeizures()!.length,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      Seizure seizure = viewModel.getSeizures()![index];
                      return getListElement(seizure);
                    },
                  )))
              ],
            )));
  }
}
