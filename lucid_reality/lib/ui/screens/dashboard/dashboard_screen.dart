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
    final activeTab = useState(DashboardTab.home);
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
              items: DashboardTab.values
                  .map(
                    (item) => BottomNavigationBarItem(
                      label: item.label,
                      icon: Image(
                        image: Svg(
                          imageBasePath.plus(item.icon),
                        ),
                        color: item.getSelectionColor(activeTab.value),
                      ),
                      activeIcon: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image(
                            image: Svg(
                              imageBasePath.plus('ic_dashboard_tab_selected.svg'),
                            ),
                          ),
                          Image(
                            image: Svg(
                              imageBasePath.plus(item.icon),
                            ),
                            color: item.getSelectionColor(activeTab.value),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

enum DashboardTab {
  home(0, 'Home', 'home.svg'),
  learn(1, 'Learn', 'learn.svg'),
  pvt(2, 'PVT', 'brain_check.svg'),
  lucid(3, 'Lucid', 'lucid.svg'),
  sleep(4, 'Sleep', 'sleep.svg');

  const DashboardTab(this.tabIndex, this.label, this.icon);

  final int tabIndex;
  final String label;
  final String icon;

  static DashboardTab getByTabIndex(int i) {
    return DashboardTab.values.firstWhere((x) => x.tabIndex == i);
  }
}

extension DashboardTabSelection on DashboardTab {
  Color getSelectionColor(DashboardTab dashboardTab) =>
      dashboardTab == this ? NextSenseColors.royalBlue : NextSenseColors.white;
}
