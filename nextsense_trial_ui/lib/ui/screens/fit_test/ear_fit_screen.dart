import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/components/underlined_text_button.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/fit_test/ear_fit_screen_vm.dart';
import 'package:stacked/stacked.dart';

class EarFitScreen extends HookWidget {

  static const String id = 'ear_fit_screen';

  Widget buildBody(EarFitScreenViewModel viewModel, BuildContext context) {
    String bodyText = '';
    String buttonText = 'Go';
    String leftResultAsset = 'assets/images/circle_left_blue.svg';
    String rightResultAsset = 'assets/images/circle_right_blue.svg';

    switch (viewModel.earFitResultState) {
      case EarFitResultState.NO_RESULTS:
        leftResultAsset = 'assets/images/circle_left_blue.svg';
        rightResultAsset = 'assets/images/circle_right_blue.svg';
        break;
      case EarFitResultState.POOR_QUALITY_RIGHT:
        leftResultAsset = 'assets/images/circle_left_green.svg';
        rightResultAsset = 'assets/images/circle_right_red.svg';
        break;
      case EarFitResultState.POOR_QUALITY_LEFT:
        leftResultAsset = 'assets/images/circle_left_red.svg';
        rightResultAsset = 'assets/images/circle_right_green.svg';
        break;
      case EarFitResultState.POOR_QUALITY_BOTH:
        leftResultAsset = 'assets/images/circle_left_red.svg';
        rightResultAsset = 'assets/images/circle_right_red.svg';
        break;
      case EarFitResultState.GOOD_FIT:
        leftResultAsset = 'assets/images/circle_left_green.svg';
        rightResultAsset = 'assets/images/circle_right_green.svg';
        break;
    }

    switch (viewModel.earFitRunState) {
      case EarFitRunState.NOT_STARTED:
        bodyText = 'Place the earbuds in your ears so they’re comfortable and secure. '
            'Then press GO.';
        break;
      case EarFitRunState.RUNNING:
        buttonText = 'Stop';
        switch (viewModel.earFitResultState) {
          case EarFitResultState.NO_RESULTS:
            bodyText = 'Please wait while checking the signal quality.';
            break;
          case EarFitResultState.POOR_QUALITY_RIGHT:
            bodyText = 'Poor signal quality. Try adjusting the right earbud or changing the ear '
                'tip size.';
            break;
          case EarFitResultState.POOR_QUALITY_LEFT:
            bodyText = 'Poor signal quality. Try adjusting the left earbud or changing the ear tip '
                'size.';
            break;
          case EarFitResultState.POOR_QUALITY_BOTH:
            bodyText = 'Poor signal quality. The earbuds are either placed outside the ears or '
                'have poor fit.';
            break;
          case EarFitResultState.GOOD_FIT:
            bodyText = 'The ear tips you are using are a good fit for both ears.';
            break;
        }
        break;
      case EarFitRunState.FINISHED:
        if (viewModel.earFitResultState == EarFitResultState.GOOD_FIT) {
          buttonText = 'Finish setup';
        } else {
          buttonText = 'Go';
        }
        switch (viewModel.earFitResultState) {
          case EarFitResultState.NO_RESULTS:
            bodyText = 'Failed to obtain ear fit result. Please try again or contact support.';
            break;
          case EarFitResultState.POOR_QUALITY_RIGHT:
            bodyText = 'Poor signal quality. Try adjusting the right earbud or changing the ear '
                'tip size. If you cannot get a good fit, please contact support.';
            break;
          case EarFitResultState.POOR_QUALITY_LEFT:
            bodyText = 'Poor signal quality. Try adjusting the left earbud or changing the ear tip '
                'size. If you cannot get a good fit, please contact support.';
            break;
          case EarFitResultState.POOR_QUALITY_BOTH:
            bodyText = 'Poor signal quality. The earbuds are either placed outside the ears or '
                'have poor fit. If you cannot get a good fit, please contact support.';
            break;
          case EarFitResultState.GOOD_FIT:
            bodyText = 'The ear tips you are using are a good fit for both ears.';
            break;
        }
        break;
    }
    return Column(
      children: [
        Spacer(),
        HeaderText(text: 'Ear Tip Fit Test'),
        SizedBox(height: 40),
        Container(height: 100, child: MediumText(marginLeft: 20, marginRight: 20, text: bodyText,
            color: NextSenseColors.darkBlue)),
        SizedBox(height: 20),
        Center(child: Image(image: AssetImage('assets/images/earbuds.png'), width: 267)),
        SizedBox(height: 20),
        Row(children: [
          Spacer(),
          SvgPicture.asset(leftResultAsset,
              semanticsLabel: 'left result', width: 40),
          SizedBox(width: 100),
          SvgPicture.asset(rightResultAsset,
              semanticsLabel: 'right result', width: 40),
          Spacer(),
        ]),
        Spacer(),
        SimpleButton(text: Container(width: 120, margin: EdgeInsets.zero, child:
            Align(alignment: Alignment.center, child:
            MediumText(text: buttonText, color: NextSenseColors.darkBlue))),
            onTap: () => viewModel.buttonPress()),
        SizedBox(height: 20),
        if (viewModel.earFitResultState != EarFitResultState.GOOD_FIT)
          UnderlinedTextButton(text: 'Not now', onTap: () => {
            viewModel.stopAndExit()
          }),
        Spacer(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<EarFitScreenViewModel>.reactive(
        viewModelBuilder: () => EarFitScreenViewModel(),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, EarFitScreenViewModel viewModel, child) => PageScaffold(
            showBackButton: Navigator.of(context).canPop(),
            showProfileButton: false,
            child: Container(
              child: Center(child: buildBody(viewModel, context)),
            )));
  }
}