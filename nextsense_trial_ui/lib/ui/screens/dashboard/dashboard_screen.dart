import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/ui/components/device_state_debug_menu.dart';
import 'package:nextsense_trial_ui/ui/components/loading_error_widget.dart';
import 'package:nextsense_trial_ui/ui/components/session_pop_scope.dart';
import 'package:nextsense_trial_ui/ui/main_menu.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_schedule_view.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_tasks_view.dart';
import 'package:nextsense_trial_ui/ui/screens/info/support_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/settings/settings_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stacked/stacked.dart';

enum DashboardTab {
  schedule,
  tasks,
  settings,
  support
}

class DashboardScreen extends HookWidget {

  static const String id = 'dashboard_screen';

  final Navigation _navigation = getIt<Navigation>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final currentTab = useState(DashboardTab.schedule);
    return ViewModelBuilder<DashboardScreenViewModel>.reactive(
      viewModelBuilder: () => DashboardScreenViewModel(),
      onModelReady: (viewModel) => viewModel.init(),
      builder: (context, DashboardScreenViewModel viewModel, child) => SessionPopScope(
          child: SafeArea(
            child: Scaffold(
              key: _scaffoldKey,
              drawer: MainMenu(),
              body: Container(
                //padding: EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
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
                    if ([DashboardTab.schedule, DashboardTab.tasks]
                        .contains(currentTab.value))
                      _buildDayTabs(context),
                    Expanded(
                      child: PersistentTabView(
                        context,
                        onItemSelected: (index) {
                          currentTab.value = DashboardTab.values[index];
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
                          borderRadius: BorderRadius.circular(10.0),
                          colorBehindNavBar: Colors.white,
                        ),
                        popAllScreensOnTapOfSelectedTab: true,
                        popActionScreens: PopActionScreensType.all,
                        itemAnimationProperties: ItemAnimationProperties( // Navigation Bar's items animation properties.
                          duration: Duration(milliseconds: 200),
                          curve: Curves.ease,
                        ),
                        navBarStyle: NavBarStyle.style6, // Choose the nav bar style with this property.
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

    final activeColorPrimary = Colors.deepPurple;
    final inactiveColorPrimary = Colors.grey;
    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.calendar_today_outlined),
        title: ("Schedule"),
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
        icon: Icon(Icons.settings),
        title: ("Settings"),
        activeColorPrimary: activeColorPrimary,
        inactiveColorPrimary: inactiveColorPrimary
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.support_agent),
        title: ("Support"),
        activeColorPrimary: activeColorPrimary,
        inactiveColorPrimary: inactiveColorPrimary
      ),
    ];
  }


  List<Widget> _buildTabs(BuildContext context) {
    return [
      DashboardScheduleView(),
      DashboardTasksView(),
      SettingsScreen(),
      SupportScreen()
    ];
  }

  Widget _appBar(BuildContext context) {
    final viewModel = context.watch<DashboardScreenViewModel>();
    return Container(
      height: 50,
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
          Row(
            children: [
              _indicator("HDMI", viewModel.isHdmiCablePresent),
              SizedBox(width: 10,),
              _indicator("Micro SD", viewModel.isUSdPresent),
              SizedBox(width: 10,),
              DeviceStateDebugMenu(),
              SizedBox(width: 5,),
            ],
          ),
        ],
      ),
    );
  }

  Widget _indicator(String text, bool on) {
    return Opacity(
      opacity: on ? 1.0 : 0.3,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black)
        ),
        padding: EdgeInsets.all(5.0),
        child: Text(
            text + (on ? " ON" : " OFF"),
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDayTabs(BuildContext context) {
    final viewModel = context.watch<DashboardScreenViewModel>();
    List<StudyDay> days = viewModel.getDays();

    if (viewModel.isBusy) {
      return Container(
        height: 80.0,
        child: ListView.builder(
            itemCount: 5,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              return Shimmer.fromColors(
                  baseColor: Colors.grey.shade100,
                  highlightColor: Colors.grey.shade200,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                        child: Container(height: 80, width: 65, color: Colors.red,)
                    ),
                  )
              );
            }
        ),
      );
    }

    return Container(
        height: 80.0,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            StudyDay day = days[index];
            return _StudyDayCard(day);
          },
        ));
  }

}

class _StudyDayCard extends HookWidget {
  final StudyDay studyDay;
  const _StudyDayCard(this.studyDay, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardScreenViewModel>();
    final isSelected = viewModel.selectedDay == studyDay;
    final hasProtocols = viewModel.dayHasAnyScheduledProtocols(studyDay);

    useEffect(() {
      if (isSelected) {
        _ensureVisible(context);
      }
    }, []);

    final textStyle = TextStyle(
        fontSize: 20.0,
        color: isSelected ? Colors.white : Colors.black);
    return Opacity(
      opacity: hasProtocols ? 1.0 : 0.8,
      child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: InkWell(
            onTap: () {
              viewModel.selectDay(studyDay);
            },
            child: Stack(
              children: [
                Container(
                    width: 65,
                    height: 80,
                    decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white60,
                        border: Border.all(
                          color: Colors.black26,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(12))
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 5,),
                        Opacity(
                            opacity: 0.5,
                            child: Text(DateFormat('MMMM').format(studyDay.date),
                                style: textStyle.copyWith(fontSize: 10.0))),
                        Opacity(
                            opacity: 0.5,
                            child: Text(DateFormat('EE').format(studyDay.date),
                                style: textStyle)),
                        Text(studyDay.dayNumber.toString(), style: textStyle),
                      ],
                    )),
                if (hasProtocols)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white : Colors.green,
                      ),
                      width: 6,
                      height: 6,
                    ),
                  ),
              ],
            ),
          )),
    );
  }

  void _ensureVisible(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 200)).then((value) {
      Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          curve: Curves.decelerate,
          duration: const Duration(milliseconds: 160)
      );
    });
  }
}



