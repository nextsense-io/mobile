import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol/scheduled_session.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/task_card.dart';
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
  final bool surveysOnly;

  DashboardScheduleView({Key? key, this.scheduleType = "Tasks", this.surveysOnly = false})
      : super(key: key);

  final Navigation _navigation = getIt<Navigation>();

  _onProtocolClicked(BuildContext context, dynamic task) {
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
    _navigation.navigateWithCapabilityChecking(context, ProtocolScreen.id,
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

  _getOnTap(BuildContext context, Task task) {
    if (task is ScheduledSurvey) {
      return _onSurveyClicked(context, task);
    }
    if (task is ScheduledSession) {
      return _onProtocolClicked(context, task);
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
    List<dynamic> todayTasks = viewModel.getTodayTasks(surveysOnly);
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
      todayTasksWidgets = [
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
              return TaskCard(task, () => _getOnTap(context, task));
            },
          ),
        ))
      ];
    }

    List<dynamic> weeklyTasks = viewModel.getWeeklyTasks(surveysOnly);
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
                return TaskCard(task, () => _getOnTap(context, task));
              },
            )),
      ];
    }

    List<Widget> contents = [
      HeaderText(text: 'My $scheduleType'),
      SizedBox(height: 15),
    ];
    contents.addAll(todayTasksWidgets);
    contents.addAll(weeklyTasksWidgets);

    return PageScaffold(
        showBackButton: _navigation.canPop(),
        padBottom: _navigation.canPop(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: contents));
  }
}

// class _TaskProtocolRow extends HookWidget {
//
//   final ScheduledProtocol scheduledProtocol;
//
//   _TaskProtocolRow(this.scheduledProtocol, {Key? key,}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     Protocol protocol = scheduledProtocol.protocol;
//     var protocolBackgroundColor = Color(0xFF6DC5D5);
//     switch(protocol.type) {
//       case ProtocolType.variable_daytime:
//         protocolBackgroundColor = Color(0xFF82C3D3);
//         break;
//       case ProtocolType.sleep:
//         protocolBackgroundColor = Color(0xFF984DF1);
//         break;
//       case ProtocolType.eoec:
//       case ProtocolType.eyes_movement:
//       case ProtocolType.unknown:
//         protocolBackgroundColor = Color(0xFFE6AEA0);
//         break;
//     }
//
//     return Padding(
//         padding: const EdgeInsets.all(10.0),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               width: 60,
//               child: Visibility(
//                   visible: true,
//                   child: Text(protocol.startTime.hhmm,
//                       style: TextStyle(color: Colors.black))),
//             ),
//             Expanded(
//               child: Opacity(
//                 opacity: scheduledProtocol.isCompleted
//                     || scheduledProtocol.isSkipped
//                     || scheduledProtocol.isCancelled ? 0.6 : 1.0,
//                 child: Padding(
//                   padding: const EdgeInsets.only(top: 12.0),
//                   child: InkWell(
//                     onTap: () {
//                       _onProtocolClicked(context, scheduledProtocol);
//                     },
//                     child: Container(
//                         padding: const EdgeInsets.all(16.0),
//                         decoration: new BoxDecoration(
//                             color: protocolBackgroundColor,
//                             borderRadius: new BorderRadius.all(
//                                 const Radius.circular(5.0))),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Column(
//                               mainAxisAlignment:
//                               MainAxisAlignment.spaceBetween,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(protocol.description,
//                                     style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold)),
//                                 SizedBox(
//                                   height: 8,
//                                 ),
//                                 Text(humanizeDuration(protocol.minDuration),
//                                     style: TextStyle(color: Colors.white))
//                               ],
//                             ),
//                             _protocolState(scheduledProtocol)
//                           ],
//                         )),
//                   ),
//                 ),
//               ),
//             ),
//             Container(
//               width: 40,
//             ),
//           ],
//         ));
//   }
//
//   Widget _protocolState(ScheduledProtocol scheduledProtocol) {
//     switch(scheduledProtocol.state) {
//       case ProtocolState.skipped:
//         return Column(
//           children: [
//             Icon(Icons.cancel, color: Colors.white),
//             Text("Skipped", style: TextStyle(color: Colors.white),),
//           ],
//         );
//       case ProtocolState.cancelled:
//         return Column(
//           children: [
//             Icon(Icons.cancel, color: Colors.white),
//             Text("Cancelled", style: TextStyle(color: Colors.white),),
//           ],
//         );
//       case ProtocolState.completed:
//         return Icon(Icons.check_circle, color: Colors.white);
//       default: break;
//     }
//     return Container();
//   }
// }
