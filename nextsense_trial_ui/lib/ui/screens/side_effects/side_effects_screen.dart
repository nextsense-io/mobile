import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/side_effect.dart';
import 'package:nextsense_trial_ui/domain/timed_entry.dart';
import 'package:nextsense_trial_ui/ui/components/add_floating_button.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/round_background.dart';
import 'package:nextsense_trial_ui/ui/components/timed_entry_cart.dart';
import 'package:nextsense_trial_ui/ui/components/wait_widget.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/side_effects/side_effect_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/side_effects/side_effects_screen_vm.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class SideEffectsScreen extends HookWidget {
  static const String id = 'side_effects_screen';

  final Navigation _navigation = getIt<Navigation>();

  Future<dynamic> _editSideEffect(BuildContext context, dynamic sideEffect) async {
    await _navigation.navigateTo(SideEffectScreen.id, pop: true, arguments: sideEffect);
  }

  Future<dynamic> _deleteSideEffect(BuildContext context, dynamic sideEffect) async {
    SideEffectsScreenViewModel viewModel = context.read<SideEffectsScreenViewModel>();
    bool deleted = await viewModel.deleteSideEffect(sideEffect);
    if (!deleted) {
      showDialog(
          context: context,
          builder: (_) => SimpleAlertDialog(
              title: 'Error deleting',
              content: 'Please try again and contact support if you get additional errors.'));
    }
  }

  Function(BuildContext, dynamic) _getSideEffectEditFunction(TimedEntry sideEffect) {
    return _editSideEffect;
  }

  Widget getListElement(SideEffect sideEffect) {
    return Slidable(
      child: TimedEntryCard(sideEffect, _getSideEffectEditFunction(sideEffect)),
      // The end action pane is the one at the right or the bottom side.
      endActionPane: ActionPane(
        motion: ScrollMotion(),
        children: [
          CustomSlidableAction(
              backgroundColor: Colors.transparent,
              onPressed: (context) {
                _editSideEffect(context, sideEffect);
              },
              autoClose: true,
              child: RoundBackground(
                  color: Colors.white,
                  elevation: 3,
                  width: 80,
                  height: 80,
                  onPressed: () => _getSideEffectEditFunction(sideEffect),
                  child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Image(image: Svg('assets/images/pen.svg'), width: 25, height: 25)))),
          CustomSlidableAction(
              backgroundColor: Colors.transparent,
              onPressed: (context) => _deleteSideEffect(context, sideEffect),
              autoClose: true,
              child: RoundBackground(
                  color: Colors.white,
                  elevation: 3,
                  width: 80,
                  height: 80,
                  child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Image(
                          image: Svg('assets/images/thrash_can.svg'), width: 25, height: 25)))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SideEffectsScreenViewModel>.reactive(
        viewModelBuilder: () => SideEffectsScreenViewModel(),
        onModelReady: (viewModel) => viewModel.init(),
        createNewModelOnInsert: true,
        builder: (context, SideEffectsScreenViewModel viewModel, child) => PageScaffold(
            floatingActionButton: AddFloatingButton(
                onPressed: () => _navigation.navigateTo(SideEffectScreen.id, pop: true)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderText(text: 'Side Effects'),
                SizedBox(height: 10),
                if (viewModel.isBusy)
                  WaitWidget(message: 'Loading side effects...')
                else
                  Expanded(
                      child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: viewModel.getSideEffects()!.length,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      SideEffect sideEffect = viewModel.getSideEffects()![index];
                      return getListElement(sideEffect);
                    },
                  ))
              ],
            )));
  }
}
