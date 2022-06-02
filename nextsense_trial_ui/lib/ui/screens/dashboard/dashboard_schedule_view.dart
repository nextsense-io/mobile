import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
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
  DashboardScheduleView({Key? key}) : super(key: key);

  final Navigation _navigation = getIt<Navigation>();

  Future<dynamic> _onProtocolClicked(BuildContext context, dynamic task) async {
    ScheduledProtocol scheduledProtocol = task as ScheduledProtocol;

    if (scheduledProtocol.isCompleted) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Warning',
            content: 'Protocol is already completed'),
      );
      return;
    }

    if (scheduledProtocol.isSkipped || scheduledProtocol.isCancelled) {
      var msg = 'Cannot start protocol cause its already ';
      if (scheduledProtocol.isSkipped) {
        msg += 'skipped';
      } else {
        msg += 'cancelled';
      }
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Warning',
            content: msg),
      );
      return;
    }

    if (!scheduledProtocol.isAllowedToStart()) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Warning',
            content: 'This protocol can start after '
                '${scheduledProtocol.allowedStartAfter.hhmm} and before '
                '${scheduledProtocol.allowedStartBefore.hhmm}'),
      );
      return;
    }

    await _navigation.navigateWithCapabilityChecking(
        context,
        ProtocolScreen.id,
        arguments: scheduledProtocol
    );

    // Refresh dashboard since protocol state can be changed
    // TODO(alex): find better way to rebuild after pop
    context.read<DashboardScreenViewModel>().notifyListeners();
  }

  Future<dynamic> _onSurveyClicked(BuildContext context, dynamic task) async {
    ScheduledSurvey scheduledSurvey = task as ScheduledSurvey;

    if (scheduledSurvey.completed) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Warning',
            content: 'Survey is already completed'),
      );
      return;
    }

    if (scheduledSurvey.isSkipped) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Warning',
            content: 'Cannot start survey cause its already skipped'),
      );
      return;
    }

    bool completed = await _navigation.navigateTo(SurveyScreen.id, arguments: scheduledSurvey);

    if (completed) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Success',
            content: 'Survey successfully completed!'),
      );
    }
    // Refresh tasks since survey state can be changed
    context.read<DashboardScreenViewModel>().notifyListeners();
  }

  Function(BuildContext, dynamic) getOnTap(Task task) {
    if (task is ScheduledSurvey) {
      return _onSurveyClicked;
    }
    if (task is ScheduledProtocol) {
      return _onProtocolClicked;
    }
    throw UnimplementedError('Task navigation not implemented!');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardScreenViewModel>();

    if (viewModel.isBusy) {
      var loadingTextVisible =
          viewModel.studyInitialized != null && !viewModel.studyInitialized!;

      return WaitWidget(message: Text("Your study is initializing.\nPlease wait...",
          style: TextStyle(color: Colors.deepPurple, fontSize: 20),
          textAlign: TextAlign.center), textVisible: loadingTextVisible);
    }

    List<dynamic> todayTasks = viewModel.getTodayTasks();
    List<Widget> todayTasksWidgets;
    if (todayTasks.length == 0) {
      todayTasksWidgets = [Container(
          padding: EdgeInsets.all(30.0),
          child: Column(
            children: [
              Icon(Icons.event_note, size: 50, color: Colors.grey,),
              SizedBox(height: 20,),
              MediumText(text: 'No tasks'),
            ],
          ))
      ];
    } else {
      todayTasksWidgets = [
        MediumText(text: 'Today', color: NextSenseColors.purple),
        SingleChildScrollView(
          physics: ScrollPhysics(),
          child: Container(
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todayTasks.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  Task task = todayTasks[index];
                  return TaskCard(task, getOnTap(task));
                },
              )),
        )
      ];
    }

    List<dynamic> weeklyTasks = viewModel.getWeeklyTasks();
    List<Widget> weeklyTasksWidgets = [];
    if (weeklyTasks.length != 0) {
      weeklyTasksWidgets = [
        MediumText(text: 'Weekly', color: NextSenseColors.purple),
        SingleChildScrollView(
          physics: ScrollPhysics(),
          child: Container(
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: weeklyTasks.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  Task task = weeklyTasks[index];
                  return TaskCard(task, getOnTap(task));
                },
              )),
        )
      ];
    }

    List<Widget> contents = [
      HeaderText(text: 'My Tasks'),
      SizedBox(height: 15),
    ];
    contents.addAll(todayTasksWidgets);
    contents.addAll(weeklyTasksWidgets);

    return Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
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