import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/medication/medication.dart';
import 'package:nextsense_trial_ui/domain/medication/scheduled_medication.dart';
import 'package:nextsense_trial_ui/domain/session/scheduled_session.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:nextsense_trial_ui/ui/components/hour_tasks_card.dart';
import 'package:flutter_common/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/cancel_button.dart';
import 'package:nextsense_trial_ui/ui/components/card_title_text.dart';
import 'package:nextsense_trial_ui/ui/components/content_text.dart';
import 'package:nextsense_trial_ui/ui/components/emphasized_button.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medication_card.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/task_card.dart';
import 'package:nextsense_trial_ui/ui/components/themed_date_picker.dart';
import 'package:nextsense_trial_ui/ui/components/wait_widget.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/survey/survey_screen.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';
import 'package:provider/src/provider.dart';

class DashboardScheduleView extends StatelessWidget {
  final String scheduleType;
  final TaskType taskType;
  final bool showHoursColumn;

  DashboardScheduleView(
      {Key? key,
      this.scheduleType = "Tasks",
      this.taskType = TaskType.any,
      this.showHoursColumn = false})
      : super(key: key);

  final Navigation _navigation = getIt<Navigation>();

  Future _onProtocolClicked(BuildContext context, dynamic task) async {
    ScheduledSession scheduledProtocol = task as ScheduledSession;

    if (scheduledProtocol.isCompleted) {
      showDialog(
        context: context,
        builder: (_) =>
            SimpleAlertDialog(title: 'Warning', content: 'Protocol is already completed'),
      );
      return;
    }

    if (scheduledProtocol.isSkipped) {
      var msg = 'Too late to start the protocol. Please try to start the next one in the schedule.';
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(title: 'Warning', content: msg),
      );
      return;
    }

    if (!scheduledProtocol.isAllowedToStart()) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Warning',
            content: 'This protocol can start after '
                '${scheduledProtocol.allowedStartAfter!.hhmm} and before '
                '${scheduledProtocol.allowedStartBefore!.hhmm}'),
      );
      return;
    }

    // Remove task popup.
    _navigation.pop();
    await _navigation.navigateWithCapabilityChecking(context, ProtocolScreen.id,
        arguments: scheduledProtocol);

    // Refresh dashboard since protocol state can be changed
    // TODO(alex): find better way to rebuild after pop
    context.read<DashboardScreenViewModel>().notifyListeners();
  }

  _onSurveyClicked(BuildContext context, dynamic task) async {
    ScheduledSurvey scheduledSurvey = task as ScheduledSurvey;

    if (scheduledSurvey.completed) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(title: 'Warning', content: 'Survey is already completed'),
      );
      return;
    }

    if (scheduledSurvey.isSkipped) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Warning', content: 'Cannot start survey cause its already skipped'),
      );
      return;
    }

    // Remove task popup.
    _navigation.pop();
    bool completed = await _navigation.navigateTo(SurveyScreen.id, arguments: scheduledSurvey);

    if (completed && scheduledSurvey.state == SurveyState.completed) {
      showDialog(
        context: context,
        builder: (_) =>
            SimpleAlertDialog(title: 'Success', content: 'Survey successfully completed!'),
      );
    }
    // Refresh tasks since survey state can be changed
    context.read<DashboardScreenViewModel>().notifyListeners();
  }

  _onMedicationClicked(BuildContext context, dynamic task) async {
    ScheduledMedication scheduledMedication = task as ScheduledMedication;

    if (task.startDate!.isAfter(DateTime.now())) {
      return;
    }

    if (scheduledMedication.completed) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
          title: 'Medication already taken',
          content: '',
        ),
      );
      return;
    }

    if (scheduledMedication.skipped) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
          title: 'Medication already skipped',
          content: '',
        ),
      );
      return;
    }

    MedicationCard medicationCard = MedicationCard(
        task: task,
        onTakenTap: () async {
          TimeOfDay? takenTime = await showThemedTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(DateTime.now()),
          );
          if (takenTime != null) {
            DateTime takenDateTime = DateTime(
              task.startDateTime!.year,
              task.startDateTime!.month,
              task.startDateTime!.day,
              takenTime.hour,
              takenTime.minute,
            );
            if (takenDateTime.isAfter(DateTime.now())) {
              await showDialog(
                context: context,
                builder: (_) => SimpleAlertDialog(
                    title: 'Error', content: 'Cannot select a time in the future'),
              );
              _navigation.pop();
              return;
            } else {
              task.update(state: MedicationState.taken_on_time, takenDateTime: takenDateTime);
            }
          }
          _navigation.pop();
        },
        onNotTakenTap: () async {
          await showDialog<void>(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) {
              return SimpleDialog(
                children: [
                  Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                          padding: EdgeInsets.only(left: 20, right: 20),
                          child: CancelButton(onPressed: () => Navigator.of(context).pop()))),
                  Padding(
                      padding: EdgeInsets.all(20),
                      child: SingleChildScrollView(
                          child: Column(children: [
                        CardTitleText(text: 'Medication Not Taken?'),
                        SizedBox(height: 15),
                        ContentText(
                            text: 'Are you sure you want to mark this medication as not taken?',
                            color: NextSenseColors.darkBlue),
                        SizedBox(height: 15),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                          Expanded(
                              child: EmphasizedButton(
                                  text: MediumText(
                                      text: 'Yes',
                                      color: Colors.white,
                                      textAlign: TextAlign.center),
                                  enabled: true,
                                  onTap: () {
                                    Navigator.pop(context, true);
                                    task.update(state: MedicationState.skipped);
                                  })),
                          SizedBox(width: 10),
                          Expanded(
                              child: EmphasizedButton(
                                  text: MediumText(
                                      text: 'No', color: Colors.white, textAlign: TextAlign.center),
                                  enabled: true,
                                  onTap: () => Navigator.pop(context, false))),
                        ])
                      ]))),
                ],
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
              );
            },
          );
          _navigation.pop();
        });
    await medicationCard.showExpandedMedicationDialog(context, showClock: false, whenText: "");
    // Refresh tasks since medication state can be changed.
    context.read<DashboardScreenViewModel>().notifyListeners();
  }

  _getOnTap(BuildContext context, Task task) {
    if (task is ScheduledSurvey) {
      return _onSurveyClicked(context, task);
    }
    if (task is ScheduledSession) {
      return _onProtocolClicked(context, task);
    }
    if (task is ScheduledMedication) {
      return _onMedicationClicked(context, task);
    }
    throw UnimplementedError('Task navigation not implemented!');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardScreenViewModel>();

    if (viewModel.isBusy) {
      var loadingTextVisible = viewModel.studyInitialized != null && !viewModel.studyInitialized!;
      return WaitWidget(
          message: 'Your study is initializing.\nPlease wait...', textVisible: loadingTextVisible);
    }

    final todayScrollController = ScrollController();
    final weeklyScrollController = ScrollController();

    String noTasksText = 'No $scheduleType';
    if (!viewModel.studyStarted) {
      noTasksText = 'Study not started yet';
    } else if (viewModel.studyFinished) {
      noTasksText = 'Study finished';
    }
    List<dynamic> todayTasks = viewModel.getTodayTasks(taskType);
    List<Widget> todayTasksWidgets;
    if (todayTasks.length == 0) {
      todayTasksWidgets = [
        Container(
            padding: EdgeInsets.all(30.0),
            child: Column(
              children: [
                Icon(
                  Icons.event_note,
                  size: 50,
                  color: Colors.grey,
                ),
                SizedBox(
                  height: 20,
                ),
                MediumText(text: noTasksText),
              ],
            ))
      ];
    } else {
      if (showHoursColumn) {
        Map<String, List<TaskWithTap>> timeTasksWithTap = {};
        for (Task task in todayTasks) {
          TaskWithTap taskWithTap = TaskWithTap(task, () => _getOnTap(context, task));
          String time = task.windowStartTime.hmm;
          if (!timeTasksWithTap.containsKey(time)) {
            timeTasksWithTap[time] = [taskWithTap];
          } else {
            timeTasksWithTap[time]!.add(taskWithTap);
          }
        }
        List<List<TaskWithTap>> hourTasks = timeTasksWithTap.values.toList();
        hourTasks
            .sort((a, b) => a[0].task.windowStartTime.hmm.compareTo(b[0].task.windowStartTime.hmm));
        todayTasksWidgets = [
          Row(children: [
            Padding(
                padding: EdgeInsets.only(left: 8),
                child: MediumText(text: 'Time', color: NextSenseColors.darkBlue)),
            Padding(
                padding: EdgeInsets.only(left: 33),
                child: MediumText(text: 'Medicine', color: NextSenseColors.darkBlue)),
          ]),
          Expanded(
              child: Scrollbar(
            thumbVisibility: true,
            controller: todayScrollController,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              controller: todayScrollController,
              itemCount: hourTasks.length,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                return HourTasksCard(
                    time: hourTasks[index][0].task.windowStartTime.hmm, tasks: hourTasks[index]);
              },
            ),
          ))
        ];
      } else {
        todayTasksWidgets = [
          if (taskType != TaskType.medication)
            MediumText(text: 'Today', color: NextSenseColors.darkBlue),
          Expanded(
              child: Scrollbar(
            thumbVisibility: true,
            controller: todayScrollController,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              controller: todayScrollController,
              itemCount: todayTasks.length,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                Task task = todayTasks[index];
                return TaskCard(task, !this.showHoursColumn, () => _getOnTap(context, task));
              },
            ),
          ))
        ];
      }
    }

    List<dynamic> weeklyTasks = viewModel.getWeeklyTasks(taskType);
    List<Widget> weeklyTasksWidgets = [];
    if (weeklyTasks.length != 0) {
      weeklyTasksWidgets = [
        MediumText(text: 'Weekly', color: NextSenseColors.darkBlue),
        Scrollbar(
            thumbVisibility: true,
            controller: weeklyScrollController,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              controller: weeklyScrollController,
              itemCount: weeklyTasks.length,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                Task task = weeklyTasks[index];
                return TaskCard(task, true, () => _getOnTap(context, task));
              },
            )),
      ];
    }

    List<Widget> contents = [];
    if (taskType != TaskType.medication) {
      contents.addAll([
        HeaderText(text: 'My $scheduleType'),
        SizedBox(height: 15),
      ]);
    }
    contents.addAll(todayTasksWidgets);
    contents.addAll(weeklyTasksWidgets);

    if (taskType == TaskType.medication) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contents);
    }
    return PageScaffold(
        showBackButton: _navigation.canPop(),
        padBottom: _navigation.canPop(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: contents));
  }
}
