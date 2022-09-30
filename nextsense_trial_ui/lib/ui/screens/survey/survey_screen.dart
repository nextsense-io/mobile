import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/content_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/nextsense_button.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/wait_widget.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/survey/survey_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/ui_utils.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';
import 'package:provider/src/provider.dart';
import 'package:stacked/stacked.dart';

class SurveyScreen extends HookWidget {
  static const String id = 'survey_screen';

  final RunnableSurvey runnableSurvey;
  GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final CustomLogPrinter _logger = CustomLogPrinter('SurveyScreen');

  SurveyScreen(this.runnableSurvey);

  Future _saveForm(BuildContext context, SurveyScreenViewModel viewModel,
      GlobalKey<FormBuilderState> formKey, bool submitting) async {
    if (formKey.currentState != null) {
      _logger.log(Level.INFO, "Saving form");
      formKey.currentState?.save();
      bool valid = formKey.currentState!.validate();
      if (valid || !submitting) {
        _logger.log(Level.INFO, "Submitting form");
        bool submitted = await viewModel.submit(valid ? formKey.currentState!.value :
            formKey.currentState!.instantValue, valid);
        if (submitted) {
          Navigator.pop(context, true);
        } else {
          showDialog(
              context: context,
              builder: (_) => SimpleAlertDialog(
                  title: 'Error saving the form',
                  content: 'Please make sure you have a good internet connection and try again. '
                      'Please contact support if you need more help.'));
        }
      } else if (submitting) {
        _logger.log(Level.INFO, "Validation failed");
        showDialog(
            context: context,
            builder: (_) =>
                SimpleAlertDialog(
                    title: 'Form error', content: 'Please fill missing or incorrect fields'));
      }
    }
  }

  bool canProgress(SurveyScreenViewModel viewModel) {
    SurveyQuestion currentQuestion = viewModel.getVisibleQuestions()[viewModel.currentPageNumber];
    if (!currentQuestion.optional) {
      _logger.log(Level.INFO, "viewModel formValues: ${viewModel.formValues}");
      if (_formKey.currentState?.instantValue[currentQuestion.id] != null) {
        return true;
      } else {
        return false;
      }
    }
    return true;
  }

  Widget _buildBody(BuildContext context, SurveyScreenViewModel viewModel) {
    for (String questionKey in viewModel.formValues?.keys ?? []) {
      _formKey.currentState?.setInternalFieldValue(questionKey, viewModel.formValues?[questionKey],
          isSetState: false);
    }
    return PageScaffold(
        backgroundColor: NextSenseColors.lightGrey,
        showBackground: false,
        showProfileButton: false,
        backButtonCallback:
            viewModel.isBusy ? () => {} : () => _onBackButtonPressed(context, viewModel),
        child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          if (viewModel.isBusy)
            WaitWidget(message: 'Saving...')
          else
            Expanded(
                child: WhiteThemeOverride(FormBuilder(
                    key: _formKey,
                    initialValue:
                    viewModel.formValues != null ? viewModel.formValues! : {},
                    child: IntroductionScreen(
                        globalBackgroundColor: Colors.transparent,
                        pages: _getPageViewModels(context, viewModel, _formKey),
                        initialPage: viewModel.currentPageNumber,
                        showSkipButton: false,
                        showNextButton: true,
                        showBackButton: true,
                        showDoneButton: true,
                        isProgress: false,
                        onDone: () => {},
                        onSkip: () => _onBackButtonPressed(context, viewModel),
                        canProgress: () => canProgress(viewModel),
                        onChange: (pageNum) => {
                          _logger.log(Level.INFO, "page ${pageNum}"),
                          viewModel.currentPageNumber = pageNum,
                          viewModel.notifyListeners(),
                        },
                        back: const Icon(Icons.arrow_back, color: NextSenseColors.purple),
                        skip: MediumText(text: 'Skip', color: NextSenseColors.purple),
                        next:
                        const Icon(Icons.arrow_forward, color: NextSenseColors.purple),
                        done: _submitButton(context, _formKey),
                        dotsDecorator: const DotsDecorator(
                          color: NextSenseColors.translucentPurple,
                          activeColor: NextSenseColors.purple,
                        ),
                        globalFooter: LinearProgressIndicator(
                          value: viewModel.currentPageNumber /
                              (viewModel.survey.getQuestions().length - 1),
                          color: NextSenseColors.purple,
                        )
                    )))),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    _formKey = GlobalKey<FormBuilderState>();
    return ViewModelBuilder<SurveyScreenViewModel>.reactive(
        viewModelBuilder: () => SurveyScreenViewModel(runnableSurvey),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) {
          return WillPopScope(
            onWillPop: () => _onBackButtonPressed(context, viewModel),
            child: SafeArea(
              child: _buildBody(context, viewModel)
            ),
          );
        });
  }

  Future<bool> _onBackButtonPressed(BuildContext context, SurveyScreenViewModel viewModel) async {
    await _saveForm(context, viewModel, _formKey, /*submitting=*/false);
    return true;
  }

  List<PageViewModel> _getPageViewModels(
      BuildContext context, SurveyScreenViewModel viewModel, GlobalKey<FormBuilderState> formKey) {
    List<PageViewModel> pageViewModels = [];
    for (SurveyQuestion question in viewModel.getVisibleQuestions()) {
      pageViewModels.add(_getQuestionPage(question, viewModel, formKey));
    }
    return pageViewModels;
  }

  PageViewModel _getQuestionPage(SurveyQuestion question, SurveyScreenViewModel viewModel,
      GlobalKey<FormBuilderState> formKey) {
    return PageViewModel(
        titleWidget: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: question.text,
                      style: TextStyle(
                          fontSize: 18,
                          color: NextSenseColors.darkBlue,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic)),
                  if (!question.optional)
                    TextSpan(
                        text: ' *',
                        style:
                            TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w400))
                ],
              ),
            ),
          ),
        ),
        bodyWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children:[
                SizedBox(height: 20),
                Flexible(child: _SurveyQuestionWidget(question, formKey)),
                SizedBox(height: 20),
                ])
            ]));
  }

  Widget _submitButton(BuildContext context, GlobalKey<FormBuilderState> formKey) {
    final viewModel = context.read<SurveyScreenViewModel>();

    return NextsenseButton.primary(
      "Done",
      onPressed: () async {
        _saveForm(context, viewModel, _formKey, /*submitting=*/true);
      },
    );
  }
}

class _SurveyQuestionWidget extends StatelessWidget {
  static const int maxVerticalChoiceChips = 5;

  final SurveyQuestion question;
  final GlobalKey<FormBuilderState> formKey;
  final CustomLogPrinter _logger = CustomLogPrinter('SurveyQuestionWidget');

  _SurveyQuestionWidget(this.question, this.formKey, {Key? key}) : super(key: key);

  void reloadAfterChange(SurveyScreenViewModel viewModel) {
    viewModel.formValues = formKey.currentState != null ?
        Map.from(formKey.currentState!.instantValue) : null;
    _logger.log(Level.INFO, "formValues onChanged: ${viewModel.formValues}");
    viewModel.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<SurveyScreenViewModel>();
    FormBuilderField formBuilderField;
    switch (question.type) {
      case SurveyQuestionType.yesno:
        formBuilderField = FormBuilderChoiceChip(
          name: question.id,
          padding: EdgeInsets.all(0.0),
          options: _generateChoices(),
          direction: Axis.vertical,
          alignment: WrapAlignment.spaceAround,
          crossAxisAlignment: WrapCrossAlignment.center,
          validator: FormBuilderValidators.compose(_getValidators()),
          decoration: InputDecoration(border: InputBorder.none),
          onChanged: (dynamic) => reloadAfterChange(viewModel),
        );
        break;
      case SurveyQuestionType.range:
        formBuilderField = FormBuilderChoiceChip(
          name: question.id,
          padding: EdgeInsets.all(8.0),
          options: _generateChoices(),
          validator: FormBuilderValidators.compose(_getValidators()),
          decoration: InputDecoration(border: InputBorder.none),
          onChanged: (dynamic) => reloadAfterChange(viewModel),
        );
        break;
      case SurveyQuestionType.number:
        formBuilderField = FormBuilderTextField(
          name: question.id,
          decoration: InputDecoration(
            border: OutlineInputBorder(), hintText: question.hint ?? "",
          ),
          validator: FormBuilderValidators.compose(_getValidators()),
          keyboardType: TextInputType.number,
          onChanged: (dynamic) => reloadAfterChange(viewModel),
        );
        break;
      case SurveyQuestionType.text:
        formBuilderField = FormBuilderTextField(
          name: question.id,
          decoration: InputDecoration(border: OutlineInputBorder(), hintText: question.hint ?? ""),
          validator: FormBuilderValidators.compose(_getValidators()),
          keyboardType: TextInputType.text,
          maxLines: 10,
          onChanged: (dynamic) => reloadAfterChange(viewModel),
        );
        break;
      case SurveyQuestionType.choices:
        formBuilderField = FormBuilderChoiceChip(
          name: question.id,
          direction: question.choices.length > maxVerticalChoiceChips ? Axis.horizontal
              : Axis.vertical,
          padding: EdgeInsets.all(0.0),
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          options: _generateChoices(),
          validator: FormBuilderValidators.compose(_getValidators()),
          decoration: InputDecoration(border: InputBorder.none),
          onChanged: (dynamic) => reloadAfterChange(viewModel),
        );
        break;
      case SurveyQuestionType.time:
        formBuilderField = FormBuilderDateTimePicker(
          name: question.id,
          inputType: InputType.time,
          valueTransformer: (time) {
            if (time != null) {
              return time.hhmm;
            }
            return null;
          },
          decoration: InputDecoration(labelText: 'Click to select time',
              fillColor: NextSenseColors.purple, focusColor: NextSenseColors.purple),
          initialTime: TimeOfDay(hour: 12, minute: 0),
          onChanged: (dynamic) => reloadAfterChange(viewModel),
        );
        break;
      default:
        _logger.log(Level.WARNING, 'Unknown question type ${question.typeString}');
        return Container();
    }
    return formBuilderField;
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
      case SurveyQuestionType.time:
        // TODO: Handle this case.
        break;
      case SurveyQuestionType.unknown:
        // TODO: Handle this case.
        break;
    }

    if (!question.optional) {
      validators.add(FormBuilderValidators.required(errorText: "This field is required"));
    }
    return validators;
  }

  // Generate choices
  List<FormBuilderFieldOption> _generateChoices() {
    List<FormBuilderFieldOption> result = [];
    switch (question.type) {
      case SurveyQuestionType.yesno:
        result.add(FormBuilderFieldOption(
            value: SurveyYesNoChoices.no.name,
            child: WideChoiceChip('No')));
        result.add(FormBuilderFieldOption(
            value: SurveyYesNoChoices.yes.name,
            child: WideChoiceChip('Yes')));
        break;
      case SurveyQuestionType.range:
      case SurveyQuestionType.choices:
        try {
          for (SurveyQuestionChoice choice in question.choices) {
            Widget choiceChip = question.choices.length > maxVerticalChoiceChips
                ? SmallChoiceChip(choice.text) : WideChoiceChip(choice.text);
            result.add(FormBuilderFieldOption(
                value: choice.value,
                child: choiceChip));
          }
        } catch (e) {
          _logger.log(Level.WARNING, 'Failed to parse choices: ${question.choices}, $e');
          return [];
        }
        break;
      default:
        break;
    }
    return result;
  }
}

class SmallChoiceChip extends StatelessWidget {
  final String text;

  SmallChoiceChip(this.text);

  @override
  Widget build(BuildContext context) {
    return ContentText(text: text, color: NextSenseColors.darkBlue, marginBottom: 4,
            marginTop: 4, marginLeft: 4, marginRight: 4);
  }
}

class WideChoiceChip extends StatelessWidget {
  final String text;

  WideChoiceChip(this.text);

  @override
  Widget build(BuildContext context) {
    int width = MediaQuery.of(context).size.width.round();
    return Container(width: width - 100, child: Align(alignment: Alignment.center,
        child: ContentText(text: text, color: NextSenseColors.darkBlue, marginBottom: 12,
            marginTop: 12)));
  }
}
