import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/pvt_onboarding/pvt_page.dart';
import 'package:lucid_reality/ui/screens/pvt_onboarding/pvt_report_page.dart';
import 'package:lucid_reality/ui/screens/pvt_onboarding/pvt_result_page.dart';
import 'package:stacked/stacked.dart';

import 'pvt_onboarding_vm.dart';

class PVTOnboardingScreen extends HookWidget {
  static const String id = 'pvt_onboarding_screen';

  const PVTOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pageController = usePageController(initialPage: 0);
    final activePage = useState(0);
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => PVTOnboardingViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            body: Container(
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
                        PVTPage(viewModel),
                        PVTReportPage(viewModel),
                        PVTResultPage(viewModel),
                      ],
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
        );
      },
    );
  }
}
