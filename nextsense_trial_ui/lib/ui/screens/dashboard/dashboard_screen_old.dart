import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/ui/components/device_state_debug_menu.dart';
import 'package:nextsense_trial_ui/ui/components/loading_error_widget.dart';
import 'package:nextsense_trial_ui/ui/components/session_pop_scope.dart';
import 'package:nextsense_trial_ui/ui/main_menu.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_old_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_tasks_view.dart';
import 'package:nextsense_trial_ui/ui/screens/info/support_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/settings/settings_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stacked/stacked.dart';

enum DashboardTab {
  schedule,
  tasks,
  settings,
  support
}

class DashboardOldScreen extends HookWidget {

  static const String id = 'dashboard_old_screen';

  final _preferences = getIt<Preferences>();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final currentTab = useState<DashboardTab>(DashboardTab.schedule);

    bool showDayTabs() {
      if (currentTab.value == DashboardTab.schedule)
        return true;

      if (currentTab.value == DashboardTab.tasks) {
        return _preferences.getBool(
            PreferenceKey.showDayTabsForTasks);
      }

      return false;
    }

    return ViewModelBuilder<DashboardScreenOldViewModel>.reactive(
      viewModelBuilder: () => DashboardScreenOldViewModel(),
      onModelReady: (viewModel) => viewModel.init(),
      builder: (context, DashboardScreenOldViewModel viewModel, child) => SessionPopScope(
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
                    Visibility(
                        visible: showDayTabs(),
                        child: _DayTabs()
                    ),
                    Expanded(
                      child: PersistentTabView(
                        context,
                        onItemSelected: (index) {
                          currentTab.value = DashboardTab.values[index];
                          if (currentTab.value == DashboardTab.schedule
                              || currentTab.value == DashboardTab.tasks) {
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
                        navBarHeight: 65,// Choose the nav bar style with this property.
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
      // DashboardScheduleView(),
      DashboardTasksView(),
      SettingsScreen(),
      SupportScreen()
    ].map((element) => Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/dashboard_background.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: element,
    )).toList();
  }

  Widget _appBar(BuildContext context) {
    final viewModel = context.watch<DashboardScreenOldViewModel>();
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
}

class _DayTabs extends StatefulWidget {
  const _DayTabs({Key? key}) : super(key: key);

  @override
  State<_DayTabs> createState() => _DayTabsState();
}

class _DayTabsState extends State<_DayTabs> {

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  StreamSubscription? subscription;

  @override
  void initState() {
    super.initState();

    final viewModel = context.read<DashboardScreenOldViewModel>();
    subscription = viewModel.studyDayChangeStream.stream.listen(_scrollToDay);
  }

  @override
  void dispose() {
    super.dispose();
    subscription?.cancel();
  }

  void _scrollToDay(int dayNumber) {
    // Add litle delay to make sure scroll initialized
    Future.delayed(Duration(milliseconds: 10), () {
      var firstVisibleDayIndex,lastVisibleDayIndex;
      try {
        firstVisibleDayIndex =
            itemPositionsListener.itemPositions.value.first.index;
        lastVisibleDayIndex =
            itemPositionsListener.itemPositions.value.last.index;
      } catch (e) {
        return;
      }
      final selectedDayIndex = dayNumber - 1;
      // If selected day is near edge of screen, scroll little bit to make
      // sure nearest days are also visible
      if (firstVisibleDayIndex == selectedDayIndex ||
          lastVisibleDayIndex == selectedDayIndex) {
        if (itemScrollController.isAttached) {
          var index = dayNumber - 3;
          if (index < 0) {
            index = 0;
          }
          itemScrollController.scrollTo(
              index: index,
              duration: Duration(milliseconds: 400),
              curve: Curves.ease
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardScreenOldViewModel>();
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

    var initialScrollIndex = viewModel.selectedDayNumber - 3;
    if (initialScrollIndex < 0) {
      initialScrollIndex = 0;
    }

    return Container(
        height: 80.0,
        child: ScrollablePositionedList.builder(
          initialScrollIndex: initialScrollIndex,
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          itemBuilder: (context, index) => _StudyDayCard(days[index]),
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
        )
    );
  }
}

class _StudyDayCard extends HookWidget {
  final StudyDay studyDay;
  const _StudyDayCard(this.studyDay, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardScreenOldViewModel>();
    final isSelected = viewModel.selectedDay == studyDay;
    final hasProtocols = viewModel.dayHasAnyScheduledProtocols(studyDay);

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
                        Text(studyDay.dayOfMonth.toString(), style: textStyle),
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
}



