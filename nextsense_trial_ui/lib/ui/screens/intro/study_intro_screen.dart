import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/components/content_text.dart';
import 'package:nextsense_trial_ui/ui/components/emphasized_button.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/intro/study_intro_screen_vm.dart';
import 'package:stacked/stacked.dart';

class StudyIntroScreen extends HookWidget {

  static const String id = 'study_intro_screen';

  final Navigation _navigation = getIt<Navigation>();

  List<PageViewModel> _getPageViewModels(BuildContext context, StudyIntroScreenViewModel viewModel) {
    final ThemeData theme = Theme.of(context);
    theme.copyWith(
      scaffoldBackgroundColor: Colors.white,
    );
    return viewModel.getIntroPageContents().map((e) => PageViewModel(
        titleWidget: Align(alignment: Alignment.centerLeft, child: HeaderText(text: e.title)),
        bodyWidget: ContentText(text: e.content, color: NextSenseColors.purple),
        image: e.localCachedImage != null ?
            Image.file(e.localCachedImage!, width: MediaQuery.of(context).size.width) :
            null
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<StudyIntroScreenViewModel>.reactive(
        viewModelBuilder: () => StudyIntroScreenViewModel(),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) {
          return WillPopScope(
            onWillPop: () => _onBackButtonPressed(context, viewModel),
            child: IntroductionScreen(
                pages: _getPageViewModels(context, viewModel),
                showSkipButton: true,
                showNextButton: false,
                onDone: () => _navigation.navigateTo(DashboardScreen.id, replace: true),
                onSkip: () => _navigation.navigateTo(DashboardScreen.id, replace: true),
                back: const Icon(Icons.arrow_back),
                skip: MediumText(text: 'Skip', color: NextSenseColors.purple),
                next: const Icon(Icons.arrow_forward, color: NextSenseColors.purple),
                done: EmphasizedButton(text: MediumText(text: 'Continue', color: Colors.white),
                  onTap: () => _navigation.navigateTo(DashboardScreen.id, replace: true),),
                dotsDecorator: const DotsDecorator(
                  color: NextSenseColors.translucentPurple,
                  activeColor: NextSenseColors.purple,
              ),
            ),
          );
        }
    );
  }

  Future<bool> _onBackButtonPressed(
      BuildContext context, StudyIntroScreenViewModel viewModel) async {
    Navigator.pop(context, false);
    return true;
  }
}