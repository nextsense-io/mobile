import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/nextsense_button.dart';
import 'package:nextsense_trial_ui/ui/screens/survey/survey_screen_vm.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:provider/src/provider.dart';
import 'package:stacked/stacked.dart';

class SurveyScreen extends HookWidget {

  static const String id = 'survey_screen';

  final CustomLogPrinter _logger = CustomLogPrinter('Assessment');

  final ScheduledSurvey scheduledSurvey;

  SurveyScreen(this.scheduledSurvey);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SurveyScreenViewModel>.reactive(
        viewModelBuilder: () => SurveyScreenViewModel(scheduledSurvey),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) {
            final steps = [
              _SurveyIntroduction(),
              _SurveyForm(),
            ];
            return WillPopScope(
              onWillPop: () => _onBackButtonPressed(context, viewModel),
              child: steps[viewModel.currentStep],
            );
        }
    );
  }

  _onBackButtonPressed(BuildContext context, SurveyScreenViewModel viewModel) {
    Navigator.pop(context, false);
  }

}

class _SurveyIntroduction extends StatelessWidget {
  const _SurveyIntroduction({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<SurveyScreenViewModel>();
    return SafeArea(
        child: Scaffold(
          body: Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                Expanded(child: Column(children: [
                Text(viewModel.survey.name,
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 20,
                ),
                Text(viewModel.survey.introText, style: TextStyle(fontSize: 20)),
              ],
            )),
            NextsenseButton.primary('Start Survey', onPressed: (){
              viewModel.currentStep = SurveyScreenStep.form.index;
            }),
          ],
            ),
          ),
        )
    );
  }
}

class _SurveyForm extends StatelessWidget {

  final CustomLogPrinter _logger = CustomLogPrinter('_SurveyForm');

  final _formKey = GlobalKey<FormBuilderState>();

  _SurveyForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final survey = context.read<SurveyScreenViewModel>().survey;
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
                        SurveyQuestion question = survey.questions[index];
                        return _SurveyQuestionWidget(question);
                      },
                      separatorBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Divider(),
                        );
                      },
                    )),
                SizedBox(height: 20,),
                Row(
                  children: [
                    Expanded(
                      child: NextsenseButton.secondary(
                        "Cancel",
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                      ),
                    ),
                    SizedBox(width: 20,),
                    Expanded(
                      child: _submitButton(context),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _submitButton(BuildContext context) {
    final viewModel = context.read<SurveyScreenViewModel>();
    return NextsenseButton.primary(
      "Submit",
      onPressed: () {
        if (_formKey.currentState!=null) {
          _formKey.currentState?.save();
          if (_formKey.currentState!.validate()) {
            viewModel.submit(_formKey.currentState!.value);
            Navigator.pop(context, true);
          } else {
            _logger.log(Level.WARNING, "validation failed");
            showDialog(
                context: context,
                builder: (_) => SimpleAlertDialog(
                    title: 'Form error',
                    content:
                    'Please fill missing or incorrect fields'));
          }
        }
      },
    );
  }
}


class _SurveyQuestionWidget extends StatelessWidget {

  final CustomLogPrinter _logger = CustomLogPrinter('SurveyQuestionWidget');

  final SurveyQuestion question;

  _SurveyQuestionWidget(this.question, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FormBuilderField formBuilderField;
    switch (question.type) {
      case SurveyQuestionType.yesno:
        formBuilderField = FormBuilderChoiceChip(
          name: question.id,
          padding: EdgeInsets.all(8.0),
          options: [
            FormBuilderFieldOption(
                value: 'Yes',
                child: Text(
                  'Yes',
                  style: TextStyle(fontSize: 20),
                )),
            FormBuilderFieldOption(
                value: 'No',
                child: Text(
                  'No',
                  style: TextStyle(fontSize: 20),
                )),
          ],
          validator: FormBuilderValidators.compose(_getValidators()),
          decoration: InputDecoration(
              border: InputBorder.none
          ),
        );
        break;
      case SurveyQuestionType.range:
        formBuilderField = FormBuilderChoiceChip(
          name: question.id,
          padding: EdgeInsets.all(8.0),
          options: _generateChoices(),
          validator: FormBuilderValidators.compose(_getValidators()),
          decoration: InputDecoration(
              border: InputBorder.none
          ),
        );
        break;
      case SurveyQuestionType.number:
        formBuilderField = FormBuilderTextField(
          name: question.id,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
          validator: FormBuilderValidators.compose(_getValidators()),
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
          validator: FormBuilderValidators.compose(_getValidators()),
          keyboardType: TextInputType.text,
          maxLines: 10,
        );
        break;
      case SurveyQuestionType.choices:
        formBuilderField = FormBuilderChoiceChip(
          name: question.id,
          padding: EdgeInsets.all(8.0),
          options: _generateChoices(),
          validator: FormBuilderValidators.compose(_getValidators()),
          decoration: InputDecoration(
              border: InputBorder.none
          ),
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
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: question.text,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                if (!question.optional)
                  TextSpan(text: ' *',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold))
              ],
            ),
          ),
        ),
        formBuilderField
      ],
    );
  }

  List<FormFieldValidator> _getValidators() {
    List<FormFieldValidator> validators = [];
    switch (question.type) {

      case SurveyQuestionType.yesno:
      // TODO: Handle this case.
        break;
      case SurveyQuestionType.range:
      // TODO: Handle this case.
        break;
      case SurveyQuestionType.number:
      // TODO: Handle this case.
        break;
      case SurveyQuestionType.choices:
      // TODO: Handle this case.
        break;
      case SurveyQuestionType.text:
      // TODO: Handle this case.
        break;
      case SurveyQuestionType.unknown:
      // TODO: Handle this case.
        break;
    }

    if (!question.optional) {
      validators.add(
          FormBuilderValidators.required(errorText: "This field is required"));
    }
    return validators;
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
      case SurveyQuestionType.choices:
        try {
          for (SurveyQuestionChoice choice in question.choices) {
            result.add(FormBuilderFieldOption(
                value: choice.value, child: Text(choice.text, style: TextStyle(fontSize: 20),)));
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