import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/survey/adhoc_survey.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/profile/profile_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/survey/survey_screen.dart';
import 'package:provider/src/provider.dart';

class StartAdhocSurveyDialog extends HookWidget {
  StartAdhocSurveyDialog({Key? key}) : super(key: key);

  final Navigation _navigation = getIt<Navigation>();

  @override
  Widget build(BuildContext context) {

    final profileViewModel = context.read<ProfileScreenViewModel>();

    List<SimpleDialogOption> options = profileViewModel.getAdhocSurveys()
        .map((survey) =>
        SimpleDialogOption(
          onPressed: () async {
            bool completed = await _navigation.navigateTo(
                SurveyScreen.id, arguments:
                AdhocSurvey(survey, profileViewModel.studyId));
            Navigator.pop(context, completed);
          },
          child: Container(
              color: Colors.blue,
              padding: EdgeInsets.all(20.0),
              child: Text(survey.name, style: TextStyle(
                fontSize: 20, color: Colors.white
              ),),
          ),
        )).toList();

    return SimpleDialog(
      title: const Text('Select survey to start'),
      children: options,
    );
  }
}
