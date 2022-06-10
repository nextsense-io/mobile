import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/big_text.dart';
import 'package:nextsense_trial_ui/ui/components/clickable_zone.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/seizure.dart';
import 'package:nextsense_trial_ui/ui/components/content_text.dart';
import 'package:nextsense_trial_ui/ui/components/emphasized_text.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/components/wait_widget.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/seizures/seizure_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/seizures/seizures_screen.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';
import 'package:stacked/stacked.dart';

class SeizureScreen extends HookWidget {
  static const String id = 'seizure_screen';

  final Navigation _navigation = getIt<Navigation>();
  final Seizure? seizure;

  SeizureScreen(this.seizure);

  List<FormBuilderFieldOption> _getTriggerOptions() {
    return Trigger.values
        .map((trigger) => FormBuilderFieldOption(
            value: trigger.label,
            child: ContentText(text: trigger.label, color: NextSenseColors.darkBlue)))
        .toList();
  }

  List<PageViewModel> _getPageViewModels(BuildContext context, SeizureScreenViewModel viewModel) {
    return [
      PageViewModel(
          titleWidget: Align(
              alignment: Alignment.centerLeft,
              child: EmphasizedText(text: 'What time did your seizure occur?')),
          bodyWidget: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            ClickableZone(
                onTap: () async {
                  viewModel.changeSeizureDate(await showDatePicker(
                    context: context,
                    firstDate: DateTime(2022),
                    lastDate: DateTime.now(),
                    initialDate: viewModel.getSeizureDate(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: NextSenseColors.lightGrey, // header background color
                            onPrimary: NextSenseColors.purple, // header text color
                            onSurface: NextSenseColors.purple, // body text color
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              primary: NextSenseColors.purple, // button text color
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  ));
                },
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.calendar_today_outlined, size: 20, color: NextSenseColors.purple),
                  SizedBox(width: 5),
                  HeaderText(text: viewModel.getSeizureDate().date, color: NextSenseColors.purple)
                ])),
            SizedBox(height: 20),
            ClickableZone(
                onTap: () async {
                  viewModel.changeSeizureTime(await showTimePicker(
                    context: context,
                    initialTime: viewModel.getSeizureTime(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: NextSenseColors.lightGrey, // header background color
                            onPrimary: NextSenseColors.purple, // header text color
                            onSurface: NextSenseColors.purple, // body text color
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              primary: NextSenseColors.purple, // button text color
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  ));
                },
                child: BigText(text: viewModel.getSeizureTime().hmma)),
          ])),
      PageViewModel(
          titleWidget: Align(
              alignment: Alignment.centerLeft,
              child:
                  EmphasizedText(text: 'Can you think of any possible trigger for this seizure?')),
          bodyWidget: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ContentText(text: 'You can select multiple triggers.', color: NextSenseColors.darkBlue),
            FormBuilderFilterChip(
              name: 'triggers',
              padding: EdgeInsets.all(8.0),
              backgroundColor: NextSenseColors.transparent,
              selectedColor: NextSenseColors.purple,
              showCheckmark: false,
              options: _getTriggerOptions(),
              decoration: InputDecoration(border: InputBorder.none),
              initialValue: viewModel.triggers,
              onChanged: (values) => viewModel.triggers = values as List<dynamic>,
            )
          ])),
      PageViewModel(
          titleWidget: Align(alignment: Alignment.centerLeft, child: EmphasizedText(text: 'Note')),
          bodyWidget: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ContentText(
                text: 'Describe what happened before and after the seizure.',
                color: NextSenseColors.darkBlue),
            SizedBox(height: 20),
            FormBuilderTextField(
              name: 'note',
              decoration: InputDecoration(
                hintText: 'e.g I had an aura before the seizure and got to a safe place before my '
                    'seizure started.',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(color: Colors.grey)),
              ),
              onChanged: (value) => viewModel.note = value as String,
              keyboardType: TextInputType.text,
              maxLines: 10,
              initialValue: viewModel.note,
            )
          ])),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SeizureScreenViewModel>.reactive(
        viewModelBuilder: () => SeizureScreenViewModel(),
        onModelReady: (viewModel) => viewModel.initWithSeizure(seizure),
        createNewModelOnInsert: true,
        builder: (context, SeizureScreenViewModel viewModel, child) => WillPopScope(
            child: PageScaffold(
                backgroundColor: NextSenseColors.lightGrey,
                showBackground: false,
                showProfileButton: false,
                backButtonCallback: viewModel.isBusy
                    ? () => {}
                    : () => _navigation.navigateTo(SeizuresScreen.id, replace: true),
                child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  if (viewModel.isBusy)
                    WaitWidget(message: 'Saving seizure...')
                  else
                    Expanded(
                        child: ThemeOverride(IntroductionScreen(
                      globalBackgroundColor: Colors.transparent,
                      pages: _getPageViewModels(context, viewModel),
                      showSkipButton: false,
                      showNextButton: true,
                      showBackButton: true,
                      showDoneButton: true,
                      onDone: () => {},
                      onSkip: () => _navigation.navigateTo(SeizuresScreen.id, replace: true),
                      back: const Icon(Icons.arrow_back, color: NextSenseColors.purple),
                      skip: MediumText(text: 'Skip', color: NextSenseColors.purple),
                      next: const Icon(Icons.arrow_forward, color: NextSenseColors.purple),
                      done: SimpleButton(
                          text: MediumText(text: 'Save', color: NextSenseColors.purple),
                          onTap: () async {
                            bool saved = await viewModel.saveSeizure();
                            if (!saved) {
                              showDialog(
                                  context: context,
                                  builder: (_) => SimpleAlertDialog(
                                      title: 'Error saving',
                                      content: 'Please try again and contact support if you get '
                                          'additional errors.'));
                            } else {
                              _navigation.navigateTo(SeizuresScreen.id, replace: true);
                            }
                          }),
                      dotsDecorator: const DotsDecorator(
                        color: NextSenseColors.translucentPurple,
                        activeColor: NextSenseColors.purple,
                      ),
                    ))),
                ])),
            onWillPop: () async {
              _navigation.navigateTo(SeizuresScreen.id, replace: true);
              return true;
            }));
  }
}

class ThemeOverride extends StatelessWidget {
  final Widget child;

  const ThemeOverride(this.child);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Theme(
        child: child,
        data: themeData.copyWith(
          scaffoldBackgroundColor: Colors.white,
        ));
  }
}
