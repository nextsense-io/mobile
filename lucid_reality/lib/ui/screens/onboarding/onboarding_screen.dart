import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/onboarding/brain_checking.dart';
import 'package:lucid_reality/ui/screens/onboarding/how_it_screen.dart';
import 'package:lucid_reality/ui/screens/onboarding/onboarding_screen_vm.dart';
import 'package:lucid_reality/ui/screens/onboarding/questions_screen.dart';
import 'package:lucid_reality/ui/screens/onboarding/sleep_screen.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

import 'dream_screen.dart';
import 'learn_screen.dart';
import 'lets_go_screen.dart';

class OnboardingScreen extends HookWidget {
  static const String id = 'onboarding_screen';

  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pageController = usePageController(initialPage: 0);
    final activePage = useState(0);
    final pages = useRef<List<Widget>>([]);
    final viewModel = useRef(OnboardingScreenViewModel());
    useEffect(() {
      pages.value = [
        QuestionsScreen(viewModel: viewModel.value),
        const HowItScreen(),
        const BrainChecking(),
        const SleepScreen(),
        const LearnScreen(),
        const DreamScreen(),
        const LetsGoScreen(),
      ];
      return null;
    }, []);
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => viewModel.value,
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            body: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        imageBasePath.plus("onboarding_bg.png"),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                PageView.builder(
                  controller: pageController,
                  onPageChanged: (int page) {
                    activePage.value = page;
                  },
                  itemCount: pages.value.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: index == 0 ? 0 : 60),
                      child: pages.value[index % pages.value.length],
                    );
                  },
                ),
                Visibility(
                  visible: activePage.value != 0,
                  child: Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      onPressed: () {},
                      icon: Image.asset(
                        imageBasePath.plus("close_button.png"),
                        height: 34,
                        width: 34,
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: activePage.value != 0 && (activePage.value + 1) < pages.value.length,
                  child: Positioned(
                    left: 0,
                    bottom: 0,
                    height: 100,
                    child: Container(
                      padding: const EdgeInsets.only(left: 24),
                      child: TextButton(
                        onPressed: () {
                          viewModel.redirectToDashboard();
                        },
                        child: Text(
                          "SKIP",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: NextSenseColors.lightBlue),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      pages.value.length,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: InkWell(
                          onTap: () {
                            pageController.animateToPage(index,
                                duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
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
                Visibility(
                  visible: activePage.value != 0,
                  child: Positioned(
                    right: 0,
                    bottom: 0,
                    height: 100,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: IconButton(
                        onPressed: () {
                          if ((activePage.value + 1) == pages.value.length) {
                            viewModel.redirectToDashboard();
                          } else {
                            pageController.animateToPage(
                                (activePage.value + 1) % pages.value.length,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeIn);
                          }
                        },
                        icon: Image.asset(
                          imageBasePath.plus("forward_arrow.png"),
                          height: 34,
                          width: 34,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
