import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/ui/components/background_container.dart';
import 'package:nextsense_trial_ui/ui/components/loading_error_widget.dart';
import 'package:nextsense_trial_ui/ui/components/session_pop_scope.dart';
import 'package:nextsense_trial_ui/ui/main_menu.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_home_view.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_progress_view.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_schedule_view.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:stacked/stacked.dart';

enum HomeTab {
  home,
  tasks,
  progress
}

class DashboardScreen extends HookWidget {

  static const String id = 'dashboard_screen';

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final currentTab = useState<HomeTab>(HomeTab.home);

    return ViewModelBuilder<DashboardScreenViewModel>.reactive(
      viewModelBuilder: () => DashboardScreenViewModel(),
      onModelReady: (viewModel) => viewModel.init(),
      builder: (context, DashboardScreenViewModel viewModel, child) => SessionPopScope(
          child: SafeArea(
            child: Scaffold(
              key: _scaffoldKey,
              drawer: MainMenu(),
              body: Container(
                // padding: EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: viewModel.hasError ? [
                    _appBar(context),
                    LoadingErrorWidget(viewModel.error(viewModel) as String,
                        onTap: () {
                          viewModel.loadData();
                        })
                  ] : [
                    _appBar(context),
                    // Visibility(
                    //     visible: showDayTabs(),
                    //     child: _DayTabs()
                    // ),
                    Expanded(
                      child: PersistentTabView(
                        context,
                        onItemSelected: (index) {
                          currentTab.value = HomeTab.values[index];
                          if (currentTab.value == HomeTab.tasks) {
                            viewModel.selectToday();
                          }
                        },
                        screens: _buildTabs(context),
                        items: _navBarsItems(),
                        confineInSafeArea: true,
                        backgroundColor: Colors.white, // Default is Colors.white.
                        handleAndroidBackButtonPress: true, // Default is true.
                        resizeToAvoidBottomInset: true, // This needs to be true if you want to move up the screen when keyboard appears. Default is true.
                        stateManagement: true, // Default is true.
                        hideNavigationBarWhenKeyboardShows: true, // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
                        decoration: NavBarDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          colorBehindNavBar: Colors.white,
                        ),
                        popAllScreensOnTapOfSelectedTab: true,
                        popActionScreens: PopActionScreensType.all,
                        itemAnimationProperties: ItemAnimationProperties( // Navigation Bar's items animation properties.
                          duration: Duration(milliseconds: 200),
                          curve: Curves.ease,
                        ),
                        navBarStyle: NavBarStyle.style8,
                        navBarHeight: 65, // Choose the nav bar style with this property.
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
    );
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    final activeColorPrimary = NextSenseColors.purple;
    final inactiveColorPrimary = NextSenseColors.grey;
    return [
      PersistentBottomNavBarItem(
          icon: Icon(Icons.home_outlined),
          title: ("Home"),
          activeColorPrimary: activeColorPrimary,
          inactiveColorPrimary: inactiveColorPrimary
      ),
      PersistentBottomNavBarItem(
          icon: Icon(Icons.list_alt),
          title: ("Tasks"),
          activeColorPrimary: activeColorPrimary,
          inactiveColorPrimary: inactiveColorPrimary
      ),
      PersistentBottomNavBarItem(
          icon: Icon(Icons.access_time_outlined),
          title: ("Progress"),
          activeColorPrimary: activeColorPrimary,
          inactiveColorPrimary: inactiveColorPrimary
      ),
    ];
  }

  Widget _appBar(BuildContext context) {
    return Container(
      height: 50,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.menu,
              size: 30,
              color: Colors.black,
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabs(BuildContext context) {
    return [
      DashboardHomeView(),
      DashboardScheduleView(),
      DashboardProgressView()
    ].map((element) => BackgroundContainer(child: element)).toList();
  }
}