import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/survey.dart';
import 'package:nextsense_trial_ui/ui/components/nextsense_button.dart';
import 'package:nextsense_trial_ui/ui/screens/survey/survey_screen_vm.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:stacked/stacked.dart';

class SurveyScreen extends HookWidget {

  static const String id = 'survey_screen';

  final Survey survey;

  final _formKey = GlobalKey<FormBuilderState>();

  SurveyScreen(this.survey);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SurveyScreenViewModel>.reactive(
        viewModelBuilder: () => SurveyScreenViewModel(survey),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) =>
            WillPopScope(
              onWillPop: () => _onBackButtonPressed(context, viewModel),
              child: _body(context, viewModel),
            ));
  }

  Widget _body(BuildContext context, SurveyScreenViewModel viewModel) {
    return Scaffold(
      body: FormBuilder(
        key: _formKey,
        child: Container(
          padding: EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            physics: ScrollPhysics(),
            child: Column(
              children: [
                Container(
                    child: ListView.separated(
                      scrollDirection: Axis.vertical,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: survey.questions.length,
                      shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        Question question = survey.questions[index];
                        return SurveyQuestionWidget(question);
                      },
                      separatorBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Divider(),
                        );
                      },
                    )),
                SizedBox(height: 20,),
                NextsenseButton.primary(
                    "Submit",
                  onPressed: () {
                    _formKey.currentState?.save();
                    if (_formKey.currentState?.validate() ?? false) {
                      print(_formKey.currentState?.value);
                    } else {
                      print("validation failed");
                    }
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onBackButtonPressed(BuildContext context, SurveyScreenViewModel viewModel) {
    Navigator.pop(context);
  }

}

class SurveyQuestionWidget extends StatelessWidget {

  final CustomLogPrinter _logger = CustomLogPrinter('SurveyQuestionWidget');

  final Question question;

  SurveyQuestionWidget(this.question, {Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    FormBuilderField formBuilderField;
    switch (question.type) {
      case SurveyQuestionType.yesno:
        formBuilderField = FormBuilderChoiceChip(
          name: question.id,
          options: [
            FormBuilderFieldOption(
                value: 'Yes', child: Text('Yes')),
            FormBuilderFieldOption(
                value: 'No', child: Text('No')),
          ],
        );
        break;
      case SurveyQuestionType.range:
        formBuilderField = FormBuilderChoiceChip(
          name: question.id,
          options: _generateChoices(),
        );
        break;
      case SurveyQuestionType.number:
        formBuilderField = FormBuilderTextField(
          name: question.id,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
          onChanged: (value){},
          keyboardType: TextInputType.number,
        );
        break;
      case SurveyQuestionType.text:
        formBuilderField = FormBuilderTextField(
          name: question.id,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
          onChanged: (value){},
          keyboardType: TextInputType.text,
          maxLines: 10,
        );
        break;
      case SurveyQuestionType.choices:
        formBuilderField = FormBuilderChoiceChip(
          name: question.id,
          options: _generateChoices(),
        );
        break;
      default:
        _logger.log(Level.WARNING, 'Unknown question type ${question.typeString}');
        return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(question.text,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ),
        formBuilderField
      ],
    );
  }

  // Generate choices
  List<FormBuilderFieldOption> _generateChoices() {
    List<FormBuilderFieldOption> result = [];
    switch (question.type) {
      case SurveyQuestionType.yesno:
        result.add(FormBuilderFieldOption(
            value: 'Yes', child: Text('Yes')));
        result.add(FormBuilderFieldOption(
          value: 'No', child: Text('No')));
        break;
      case SurveyQuestionType.range:
        final int min,max;
        try {
          String choicesStr = question.choices as String;
          List<String> minMaxStr = choicesStr.split("-");
          min = int.parse(minMaxStr[0]);
          max = int.parse(minMaxStr[1]);
        } catch (e) {
          _logger.log(Level.WARNING,
              'Failed to parse choices: ${question.choices}');
          return [];
        }
        for (int choice = min; choice <= max; choice++) {
          result.add(FormBuilderFieldOption(
              value: choice.toString(), child: Text(choice.toString())));
        }
        break;
      case SurveyQuestionType.choices:
        List<dynamic> choices = question.choices;
        try {
          for (Map<String, dynamic> choice in choices) {
            result.add(FormBuilderFieldOption(
                value: choice['value'] as String, child: Text(choice['text']!)));
          }
        } catch (e) {
          _logger.log(Level.WARNING,
              'Failed to parse choices: ${question.choices}, $e');
          return [];
        }
        break;

      default:
        break;
    }
    return result;
  }
}
