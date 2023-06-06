import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:nextsense_trial_ui/domain/medication/planned_medication.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medication_card.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/session_pop_scope.dart';
import 'package:nextsense_trial_ui/ui/components/small_text.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_schedule_view.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stacked/stacked.dart';

enum MedicationTab {
  daily,
  all_meds
}

class MedicationList extends StatelessWidget {
  final List<PlannedMedication> medications;

  const MedicationList({Key? key, required this.medications}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final medication = medications[index];
        return PlannedMedicationCard(medication);
      },
    );
  }
}

class MedicationsScreen extends HookWidget {

  static const String id = 'medications_screen';

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  List<Widget> _buildTabs(BuildContext context) {
    return [
    Padding(padding: EdgeInsets.only(top: 10), child: _DayTabs()),
    Padding(padding: EdgeInsets.only(top: 10), child:
        MedicationList(medications: context.watch<DashboardScreenViewModel>().plannedMedications)),
    ];
  }

  Widget _buildBody(DashboardScreenViewModel viewModel, BuildContext context) {
    Widget tabBody = SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        key: _scaffoldKey,
        body: DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              bottom: TabBar(
                unselectedLabelColor: NextSenseColors.darkBlue,
                indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: NextSenseColors.purple),

                labelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                tabs: [
                  Tab(height: 30, text: 'DAILY'),
                  Tab(height: 30, text: 'ALL MEDS'),
                ],
              ),
              centerTitle: false,
              titleSpacing: 0.0,
              leadingWidth: 0,
              title: HeaderText(text: 'Medications'),
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            body: TabBarView(
              children: _buildTabs(context),
            ),
          ),
        ),
      ),
    );

    return PageScaffold(
        viewModel: viewModel, showBackButton: true, padBottom: false, child: tabBody);
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DashboardScreenViewModel>.reactive(
      viewModelBuilder: () => DashboardScreenViewModel(),
      onModelReady: (viewModel) => viewModel.init(),
      builder: (context, DashboardScreenViewModel viewModel, child) => SessionPopScope(
          child: _buildBody(viewModel, context)),
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

    final viewModel = context.read<DashboardScreenViewModel>();
    subscription = viewModel.studyDayChangeStream.stream.listen(_scrollToDay);
  }

  @override
  void dispose() {
    super.dispose();
    subscription?.cancel();
  }

  void _scrollToDay(int dayNumber) {
    // Add a little delay to make sure the scroll is initialized.
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

    var initialScrollIndex = viewModel.selectedDayNumber - 3;
    if (initialScrollIndex < 0) {
      initialScrollIndex = 0;
    }

    return Column(
      children: [
        Container(
            height: 80.0,
            child: ScrollablePositionedList.builder(
              initialScrollIndex: initialScrollIndex,
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (context, index) => _StudyDayCard(days[index]),
              itemScrollController: itemScrollController,
              itemPositionsListener: itemPositionsListener,
            )
        ),
        SizedBox(height: 10),
        Expanded(child: DashboardScheduleView(
            scheduleType: "Medications", taskType: TaskType.medication)),
      ],
    );
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
    final hasMedications = viewModel.dayHasAnyScheduledMedications(studyDay);

    return Opacity(
      opacity: hasMedications ? 1.0 : 0.8,
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
                        color: isSelected ? Colors.white70 : Colors.white10,
                        border: Border.all(
                          color: Colors.transparent,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(12))
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 5),
                        Opacity(
                            opacity: 0.5,
                            child: SmallText(text: DateFormat('MMMM').format(studyDay.date),
                                color: NextSenseColors.darkBlue)),
                        Opacity(
                            opacity: 0.5,
                            child: MediumText(text: DateFormat('EE').format(studyDay.date),
                                color: NextSenseColors.darkBlue)),
                        Opacity(
                          opacity: 0.5, child: MediumText(text: studyDay.dayOfMonth.toString(),
                                color: NextSenseColors.darkBlue))
                      ],
                    )),
                if (hasMedications)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
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