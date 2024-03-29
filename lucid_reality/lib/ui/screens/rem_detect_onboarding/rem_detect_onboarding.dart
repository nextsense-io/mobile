import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
import 'package:lucid_reality/ui/components/app_close_button.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/rem_detect_onboarding/lucid_dream_induction_page.dart';
import 'package:lucid_reality/ui/screens/rem_detect_onboarding/to_use_rem_detection_feature_page.dart';
import 'package:stacked/stacked.dart';

import 'rem_detect_onboarding_vm.dart';
import 'rem_detection_activation_page.dart';

class REMDetectionOnboarding extends HookWidget {
  static const String id = 'rem_detect_onboarding';

  const REMDetectionOnboarding({super.key});

  @override
  Widget build(BuildContext context) {
    final pageController = usePageController(initialPage: 0);
    final activePage = useState(0);
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => REMDetectionOnboardingViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            body: AppBody(
              child: Container(
                color: NextSenseColors.cardBackground,
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      top: 0,
                      child: PageView(
                        controller: pageController,
                        onPageChanged: (value) {
                          activePage.value = value;
                        },
                        children: [
                          LucidDreamInductionPage(),
                          REMDetectionActivationPage(),
                          ToUseTheRemDetectionFeaturePage(),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Visibility(
                        visible: activePage.value == 2,
                        child: AppCloseButton(
                          onPressed: () {
                            viewModel.navigateToLucidScreen();
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List<Widget>.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: InkWell(
                              onTap: () {
                                pageController.animateToPage(index,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeIn);
                              },
                              child: CircleAvatar(
                                radius: 4,
                                backgroundColor: activePage.value == index
                                    ? Colors.white
                                    : NextSenseColors.blueColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
