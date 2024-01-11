import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
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
  final _pages = <Widget>[];

  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = useRef(DashboardScreenViewModel());
    final activeTab = useState(DashboardTab.pvt);
    useEffect(() {
      _pages.addAll([
        HomeScreen(
          viewModel: viewModel.value,
        ),
        const LearnScreen(),
        const PsychomotorVigilanceTestListScreen(),
        const LucidScreen(),
        SleepScreen()
      ]);
      viewModel.value.changeTab = (tab) {
        activeTab.value = tab;
      };
      return null;
    }, []);
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => viewModel.value,
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            body: AppBody(child: _pages.elementAt(activeTab.value.tabIndex)),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: activeTab.value.tabIndex,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              selectedItemColor: Colors.white,
              unselectedItemColor: NextSenseColors.royalBlue,
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                activeTab.value = DashboardTab.getByTabIndex(index);
              },
              items: [
                BottomNavigationBarItem(
                  label: "Home",
                  icon: Image(
                    image: Svg(imageBasePath.plus('home.svg')),
                    color: activeTab.value == DashboardTab.home
                        ? Colors.white
                        : NextSenseColors.royalBlue,
                  ),
                ),
                BottomNavigationBarItem(
                  label: "Learn",
                  icon: Image(
                    image: Svg(imageBasePath.plus('learn.svg')),
                    color: activeTab.value == DashboardTab.learn
                        ? Colors.white
                        : NextSenseColors.royalBlue,
                  ),
                ),
                BottomNavigationBarItem(
                  label: "PVT",
                  icon: Image(
                    image: Svg(imageBasePath.plus('brain_check.svg')),
                    color: activeTab.value == DashboardTab.pvt
                        ? Colors.white
                        : NextSenseColors.royalBlue,
                  ),
                ),
                BottomNavigationBarItem(
                  label: "Lucid",
                  icon: Image(
                    image: Svg(imageBasePath.plus('lucid.svg')),
                    color: activeTab.value == DashboardTab.lucid
                        ? Colors.white
                        : NextSenseColors.royalBlue,
                  ),
                ),
                BottomNavigationBarItem(
                  label: "Sleep",
                  icon: Image(
                    image: Svg(imageBasePath.plus('sleep.svg')),
                    color: activeTab.value == DashboardTab.sleep
                        ? Colors.white
                        : NextSenseColors.royalBlue,
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

enum DashboardTab {
  home(0),
  learn(1),
  pvt(2),
  lucid(3),
  sleep(4);

  const DashboardTab(this.tabIndex);

  final int tabIndex;

  static DashboardTab getByTabIndex(int i) {
    return DashboardTab.values.firstWhere((x) => x.tabIndex == i);
  }
}
