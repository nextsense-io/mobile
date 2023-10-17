import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/domain/enrolled_study.dart';
import 'package:flutter_common/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:flutter_common/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/components/wait_widget.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/enrolled_studies/enrolled_studies_screen_vm.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class EnrolledStudiesScreen extends HookWidget {

  static const String id = 'enrolled_studies_screen';

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<EnrolledStudiesScreenViewModel>.reactive(
        viewModelBuilder: () => EnrolledStudiesScreenViewModel(),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) {
          return WillPopScope(
            onWillPop: () => _onBackButtonPressed(context, viewModel),
            child: SafeArea(child: PageScaffold(child: _buildBody(context, viewModel))),
          );
        }
    );
  }

  Widget _buildBody(BuildContext context, EnrolledStudiesScreenViewModel viewModel) {
    return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 20),
                child: MediumText(text: 'Current study: ' + viewModel.currentStudyId,
                    color: NextSenseColors.darkBlue)),
            Padding(padding: EdgeInsets.only(top: 20),
                child: MediumText(text: 'Select the study to switch to',
                    color: NextSenseColors.darkBlue)),
            _EnrolledStudiesSelector()
          ]
    );
  }

  Future<bool> _onBackButtonPressed(
      BuildContext context, EnrolledStudiesScreenViewModel viewModel) async {
    Navigator.pop(context, false);
    return true;
  }
}

class _EnrolledStudiesSelector extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    EnrolledStudiesScreenViewModel viewModel = context.watch<EnrolledStudiesScreenViewModel>();

    if (!viewModel.initialised) {
      return Padding(
          padding: EdgeInsets.only(top: 50),
          child: WaitWidget(message: 'Loading the enrolled studies.\nPlease wait...'));
    }

    if (viewModel.isBusy) {
      return Padding(
          padding: EdgeInsets.only(top: 50),
          child: WaitWidget(message: 'Initializing the new study.\nPlease wait...'));
    }

    if (viewModel.enrolledStudies == null) {
      showDialog(
          context: context,
          builder: (_) => SimpleAlertDialog(
          title: "Error loading enrolled studies",
          content: "Please try again and make sure you have an active internet connection.")
      );
      return Padding(padding: EdgeInsets.all(10));
    }

    List<Widget> studyElements = [];
    for (EnrolledStudy enrolledStudy in viewModel.enrolledStudies!) {
      if (enrolledStudy.id == viewModel.currentStudyKey) {
        // Don't show the current study as a choice to switch to.
        continue;
      }
      studyElements.add(_StudySelectionItem(
          label: Padding(padding: EdgeInsets.all(10),
              child: MediumText(text: viewModel.getStudyName(enrolledStudy.id),
                  color: NextSenseColors.darkBlue)),
              onPressed: () async {
                bool studyChanged = await viewModel.changeCurrentStudy(enrolledStudy);
                if (studyChanged) {
                  Navigator.of(context).pop();
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => SimpleAlertDialog(
                        title: 'Error',
                        content: 'Could not load the study. Please try again or contact NextSense support.'),
                  );
                }
              }
      ));
    }
    return ListView(scrollDirection: Axis.vertical, shrinkWrap: true,
        padding: EdgeInsets.only(top: 20, bottom: 20), children: studyElements);
  }
}

class _StudySelectionItem extends StatelessWidget {
  final Widget label;
  final Function onPressed;

  const _StudySelectionItem({Key? key,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      child: SimpleButton(text: label, onTap: onPressed),
    );
  }
}