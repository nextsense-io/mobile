import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:nextsense_trial_ui/domain/side_effect.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/big_text.dart';
import 'package:nextsense_trial_ui/ui/components/clickable_zone.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/components/content_text.dart';
import 'package:nextsense_trial_ui/ui/components/emphasized_text.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/components/themed_date_picker.dart';
import 'package:nextsense_trial_ui/ui/components/wait_widget.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/entry_added_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/side_effects/side_effect_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/side_effects/side_effects_screen.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';
import 'package:stacked/stacked.dart';

class SideEffectScreen extends HookWidget {
  static const String id = 'side_effect_screen';

  final Navigation _navigation = getIt<Navigation>();
  final SideEffect? sideEffect;

  SideEffectScreen(this.sideEffect);

  List<FormBuilderFieldOption> _getSideEffectTypeOptions() {
    return SideEffectType.values
        .map((sideEffectType) => FormBuilderFieldOption(
            value: sideEffectType.label,
            child: ContentText(text: sideEffectType.label, color: NextSenseColors.darkBlue)))
        .toList();
  }

  List<PageViewModel> _getPageViewModels(
      BuildContext context, SideEffectScreenViewModel viewModel) {
    return [
      PageViewModel(
          titleWidget: Align(
              alignment: Alignment.centerLeft,
              child: EmphasizedText(text: 'What time did your side effect occur?')),
          bodyWidget: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            ClickableZone(
                onTap: () async {
                  viewModel.changeSideEffectDate(await showThemedDateTimePicker(
                    context: context,
                    initialDate: viewModel.getSideEffectDate()));
                },
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.calendar_today_outlined, size: 20, color: NextSenseColors.purple),
                  SizedBox(width: 5),
                  HeaderText(text: viewModel.getSideEffectDate().date,
                      color: NextSenseColors.purple)
                ])),
            SizedBox(height: 20),
            ClickableZone(
                onTap: () async {
                  viewModel.changeSideEffectTime(await showTimePicker(
                    context: context,
                    initialTime: viewModel.getSideEffectTime(),
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
                              foregroundColor: NextSenseColors.purple, // button text color
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  ));
                },
                child: BigText(text: viewModel.getSideEffectTime().hmma)),
          ])),
      PageViewModel(
          titleWidget: Align(
              alignment: Alignment.centerLeft,
              child: EmphasizedText(text: 'What side effects are you experiencing?')),
          bodyWidget: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ContentText(
                text: 'You can select multiple side effects.', color: NextSenseColors.darkBlue),
            FormBuilderFilterChip(
              name: 'side_effects',
              padding: EdgeInsets.all(8.0),
              backgroundColor: NextSenseColors.transparent,
              selectedColor: NextSenseColors.purple,
              showCheckmark: false,
              options: _getSideEffectTypeOptions(),
              decoration: InputDecoration(border: InputBorder.none),
              initialValue: viewModel.sideEffectTypes,
              onChanged: (values) => viewModel.sideEffectTypes = values as List<dynamic>,
            )
          ])),
      PageViewModel(
          titleWidget: Align(alignment: Alignment.centerLeft, child: EmphasizedText(text: 'Note')),
          bodyWidget: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ContentText(text: 'Describe your side effects.', color: NextSenseColors.darkBlue),
            SizedBox(height: 20),
            FormBuilderTextField(
              name: 'note',
              decoration: InputDecoration(
                hintText: 'Add a detailed description about your side effect.',
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
    return ViewModelBuilder<SideEffectScreenViewModel>.reactive(
        viewModelBuilder: () => SideEffectScreenViewModel(),
        onModelReady: (viewModel) => viewModel.initWithSideEffect(sideEffect),
        createNewModelOnInsert: true,
        builder: (context, SideEffectScreenViewModel viewModel, child) => WillPopScope(
            child: PageScaffold(
                backgroundColor: NextSenseColors.lightGrey,
                showBackground: false,
                showProfileButton: false,
                backButtonCallback: viewModel.isBusy
                    ? () => {}
                    : () => _navigation.navigateTo(SideEffectsScreen.id, replace: true),
                child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  if (viewModel.isBusy)
                    WaitWidget(message: 'Saving side effect...')
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
                      onSkip: () => _navigation.navigateTo(SideEffectsScreen.id, replace: true),
                      back: const Icon(Icons.arrow_back, color: NextSenseColors.purple),
                      skip: MediumText(text: 'Skip', color: NextSenseColors.purple),
                      next: const Icon(Icons.arrow_forward, color: NextSenseColors.purple),
                      done: SimpleButton(
                          text: MediumText(text: 'Save', color: NextSenseColors.purple),
                          onTap: () async {
                            bool saved = await viewModel.saveSideEffect();
                            if (!saved) {
                              showDialog(
                                  context: context,
                                  builder: (_) => SimpleAlertDialog(
                                      title: 'Error saving',
                                      content: 'Please try again and contact support if you get '
                                          'additional errors.'));
                            } else {
                              _navigation.navigateTo(EntryAddedScreen.id, replace: true,
                                  arguments: ['You have logged a side effect',
                                    Image(image: AssetImage('assets/images/hand_pen.png'))]);
                            }
                          }),
                      dotsDecorator: const DotsDecorator(
                        color: NextSenseColors.translucentPurple,
                        activeColor: NextSenseColors.purple,
                      ),
                    ))),
                ])),
            onWillPop: () async {
              _navigation.navigateTo(SideEffectsScreen.id, replace: true);
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
