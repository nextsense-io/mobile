import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nextsense_trial_ui/domain/medication/scheduled_medication.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:nextsense_trial_ui/ui/components/cancel_button.dart';
import 'package:nextsense_trial_ui/ui/components/card_title_text.dart';
import 'package:nextsense_trial_ui/ui/components/clickable_zone.dart';
import 'package:nextsense_trial_ui/ui/components/content_text.dart';
import 'package:nextsense_trial_ui/ui/components/emphasized_button.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/rounded_background.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool showTime;
  final Function onTap;
  final String title;
  final String intro;
  final Duration? duration;
  final TimeOfDay windowStartTime;
  final TimeOfDay? windowEndTime;
  final bool completed;

  TaskCard(Task task, bool showTime, Function onTap)
      : this.task = task,
        this.showTime = showTime,
        this.title = task.title,
        this.intro = task.intro,
        this.duration = task.duration,
        this.windowStartTime = task.windowStartTime,
        this.windowEndTime = task.windowEndTime,
        this.completed = task.completed,
        this.onTap = onTap;

  Future _showExpandedTaskDialog(BuildContext context,
      {required bool showClock, required String whenText}) async {
    return showDialog<void>(
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
                  Container(
                      height: 71,
                      child: _buildTaskHeadline(
                          showIcon: false, showClock: showClock, whenText: whenText)),
                  SizedBox(height: 15),
                  ContentText(text: intro, color: NextSenseColors.darkBlue),
                  SizedBox(height: 15),
                  if (!completed)
                    EmphasizedButton(
                        text: MediumText(text: 'Start', color: Colors.white),
                        enabled: true,
                        onTap: onTap)
                ]))),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
        );
      },
    );
  }

  Widget _buildTaskHeadline({required bool showIcon, required bool showClock,
      required String whenText, String? description}) {
    Widget? icon;
    if (completed) {
      icon = Expanded(
          child: SvgPicture.asset('packages/nextsense_trial_ui/assets/images/circle_checked.svg',
              semanticsLabel: 'completed', height: 20));
    } else if (task.skipped) {
      icon = Padding(padding: EdgeInsets.only(top: 6, left: 1), child: Container(
        width: 18,
        decoration: BoxDecoration(
            color: NextSenseColors.darkRed,
            shape: BoxShape.circle
        ),
        child: MediumText(text: '!', color: Colors.white, textAlign: TextAlign.center),
      ));
    } else {
      icon = Expanded(
          child: SvgPicture.asset('packages/nextsense_trial_ui/assets/images/circle.svg',
              semanticsLabel: 'not completed', height: 20));
    }
    return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          showIcon
              ? Column(children: [
                  icon,
                  Expanded(child: SizedBox(height: 1)),
                ])
              : SizedBox(height: 1),
          showIcon ? SizedBox(width: 10) : SizedBox(height: 1),
          Expanded(
              child: Column(children: [
            Expanded(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Flexible(child: CardTitleText(text: title)),
                  SizedBox(width: 5),
                  if (showClock && duration != null)
                    SvgPicture.asset('packages/nextsense_trial_ui/assets/images/clock.svg',
                        semanticsLabel: 'specific time', width: 16),
                  SizedBox(height: 5),
                  Align(
                      alignment: Alignment.topRight,
                      child: MediumText(
                        text: whenText,
                        color: NextSenseColors.blue,
                        textAlign: TextAlign.right,
                      ))
                ])),
            if (description != null)
              Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Align(
                        alignment: Alignment.bottomLeft,
                        child: MediumText(text: description))
                  ]),
            if (duration!.inMinutes > 0)
                Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                      alignment: Alignment.bottomLeft,
                      child: MediumText(text: 'Duration: ${duration!.inMinutes} min'))
                ])
          ])),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    String whenText = '';
    bool showClock = false;
    if (showTime) {
      if (windowEndTime == null) {
        whenText = windowStartTime.hmma;
        showClock = true;
      } else if (windowStartTime.hmm == '0:00' && windowEndTime!.hmm == '23:59') {
        whenText = '';
      } else {
        whenText = 'Between\n${windowStartTime.hmm}-${windowEndTime!.hmma}';
      }
    }

    return ClickableZone(
        onTap: task.type == TaskType.medication ?
        onTap : () => _showExpandedTaskDialog(context, showClock: showClock, whenText: whenText),
        child: Container(
            height: 115,
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
              child: RoundedBackground(
                  child:
                      _buildTaskHeadline(showIcon: true, showClock: showClock, whenText: whenText,
                      description: task.type == TaskType.medication ?
                      (task as ScheduledMedication).indication : null),
            ))));
  }
}
