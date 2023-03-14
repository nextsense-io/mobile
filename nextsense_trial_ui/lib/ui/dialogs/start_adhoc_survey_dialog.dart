import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/survey/adhoc_survey.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/profile/profile_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/survey/survey_screen.dart';
import 'package:provider/src/provider.dart';

class StartAdhocSurveyDialog extends HookWidget {
  StartAdhocSurveyDialog({Key? key}) : super(key: key);

  final Navigation _navigation = getIt<Navigation>();

  @override
  Widget build(BuildContext context) {
    final profileViewModel = context.read<ProfileScreenViewModel>();

    List<Widget> options = profileViewModel.getAdhocSurveys().map((survey) =>
        Padding(padding: EdgeInsets.all(15), child: SimpleButton(
          text: MediumText(text: survey.name, color: NextSenseColors.darkBlue),
          onTap: () async {
            bool? completed = await _navigation.navigateTo(
                SurveyScreen.id, arguments:
                AdhocSurvey(survey, profileViewModel.studyId));
            Navigator.pop(context, completed ?? false);
          }),
        )).toList();

    return SimpleDialog(
      title: HeaderText(text: 'Select survey to start'),
      children: options,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
    );
  }
}
