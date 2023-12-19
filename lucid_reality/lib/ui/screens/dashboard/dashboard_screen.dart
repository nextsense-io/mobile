import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:lucid_reality/ui/screens/home/home_screen.dart';
import 'package:lucid_reality/ui/screens/learn/learn_screen.dart';
import 'package:lucid_reality/ui/screens/lucid/lucid_screen.dart';
import 'package:lucid_reality/ui/screens/pvt/psychomotor_vigilance_test_list_screen.dart';
import 'package:lucid_reality/ui/screens/sleep/sleep_screen.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

class DashboardScreen extends HookWidget {
  static const String id = 'dashboard_screen';

  DashboardScreen({super.key});

  final _pages = <Widget>[
    const HomeScreen(),
    const LearnScreen(),
    const PsychomotorVigilanceTestListScreen(),
    const LucidScreen(),
    SleepScreen()
  ];

  @override
  Widget build(BuildContext context) {
    final activeTab = useState(2);
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => DashboardScreenViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    imageBasePath.plus("onboarding_bg.png"),
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: _pages.elementAt(activeTab.value),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: activeTab.value,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              selectedItemColor: Colors.white,
              unselectedItemColor: NextSenseColors.royalBlue,
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                activeTab.value = index;
              },
              items: [
                BottomNavigationBarItem(
                  label: "Home",
                  icon: Image(
                    image: Svg(imageBasePath.plus('home.svg')),
                    color: activeTab.value == 0 ? Colors.white : NextSenseColors.royalBlue,
                  ),
                ),
                BottomNavigationBarItem(
                  label: "Learn",
                  icon: Image(
                    image: Svg(imageBasePath.plus('learn.svg')),
                    color: activeTab.value == 1 ? Colors.white : NextSenseColors.royalBlue,
                  ),
                ),
                BottomNavigationBarItem(
                  label: "Mind",
                  icon: Image(
                    image: Svg(imageBasePath.plus('brain_check.svg')),
                    color: activeTab.value == 2 ? Colors.white : NextSenseColors.royalBlue,
                  ),
                ),
                BottomNavigationBarItem(
                  label: "Lucid",
                  icon: Image(
                    image: Svg(imageBasePath.plus('lucid.svg')),
                    color: activeTab.value == 3 ? Colors.white : NextSenseColors.royalBlue,
                  ),
                ),
                BottomNavigationBarItem(
                  label: "Sleep",
                  icon: Image(
                    image: Svg(imageBasePath.plus('sleep.svg')),
                    color: activeTab.value == 4 ? Colors.white : NextSenseColors.royalBlue,
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
