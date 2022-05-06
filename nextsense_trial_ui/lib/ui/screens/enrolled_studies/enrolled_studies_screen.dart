import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/domain/enrolled_study.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/wait_widget.dart';
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
            child: SafeArea(child: Scaffold(
                appBar: AppBar(
                  title: Text('Switch study'),
                ),
                body: _buildBody(context, viewModel))),
          );
        }
    );
  }

  Widget _buildBody(BuildContext context, EnrolledStudiesScreenViewModel viewModel) {
    TextStyle textStyle = TextStyle(fontSize: 22);
    return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 20),
                child: Text('Current study: ' + viewModel.currentStudyId, style: textStyle)),
            Padding(padding: EdgeInsets.only(top: 20),
                child: Text('Select the study to switch to', style: textStyle)),
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
    EnrolledStudiesScreenViewModel viewModel =
        context.read<EnrolledStudiesScreenViewModel>();

    if (!viewModel.initialised) {
      return Padding(padding: EdgeInsets.only(top: 50), child:
          WaitWidget(message: Text(
            "Loading the enrolled studies.\nPlease wait...",
            style: TextStyle(color: Colors.deepPurple, fontSize: 20),
            textAlign: TextAlign.center,
      )));
    }

    if (viewModel.isBusy) {
      return Padding(padding: EdgeInsets.only(top: 50), child:
          WaitWidget(message: Text(
            "Initializing the new study.\nPlease wait...",
            style: TextStyle(color: Colors.deepPurple, fontSize: 20),
            textAlign: TextAlign.center,
          )));
    }

    List<Widget> studyElements = [];
    for (EnrolledStudy enrolledStudy in viewModel.enrolledStudies) {
      if (enrolledStudy.id == viewModel.currentStudyId) {
        // Don't show the current study as a choice to switch to.
        continue;
      }
      studyElements.add(_StudySelectionItem(
          label: Padding(padding: EdgeInsets.all(10),
              child: Text(enrolledStudy.id, style: TextStyle(fontSize: 20.0))),
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
  final VoidCallback? onPressed;

  const _StudySelectionItem({
    Key? key,
    required this.label,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      child: Align(
        child: ElevatedButton(
          child: label,
          onPressed: onPressed,
        ),
      ),
    );
  }
}