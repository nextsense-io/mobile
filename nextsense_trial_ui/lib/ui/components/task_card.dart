import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:nextsense_trial_ui/ui/components/card_title_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/rounded_background.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Function(BuildContext, dynamic) onTap;
  final String title;
  final Duration? duration;
  final TimeOfDay windowStartTime;
  final TimeOfDay? windowEndTime;
  final bool completed;

  TaskCard(Task task, Function(BuildContext, dynamic) onTap) : this.task = task,
        this.title = task.title, this.duration = task.duration,
        this.windowStartTime = task.windowStartTime, this.windowEndTime = task.windowEndTime,
        this.completed = task.completed, this.onTap = onTap;

  // TaskCard({required this.title, required this.windowStartTime, this.windowEndTime, this.duration,
  //     required this.onTap, this.completed = false});

  @override
  Widget build(BuildContext context) {
    String whenText;
    bool showClock = false;
    if (windowEndTime == null) {
      whenText = windowStartTime.hmma;
      showClock = true;
    } else if (windowStartTime.hmm == '0:00' && windowEndTime!.hmm == '23:59') {
      whenText = '';
    } else {
      whenText = 'Between\n${windowStartTime.hmm}-${windowEndTime!.hmma}';
    }

    final row = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          completed
              ? SvgPicture.asset('assets/images/circle_checked.svg',
                  semanticsLabel: 'completed', height: 20)
              : SvgPicture.asset('assets/images/circle.svg',
                  semanticsLabel: 'completed', height: 20),
          SizedBox(width: 10),
          Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Expanded(child: CardTitleText(text: title)),
                if (duration != null)
                  Expanded(
                      child: Align(
                          alignment: Alignment.bottomLeft,
                          child: MediumText(text: 'Duration: ${duration!.inMinutes} min')))
              ])),
          SizedBox(width: 5),
          if (showClock)
            SvgPicture.asset('assets/images/clock.svg', semanticsLabel: 'specific time', width: 16),
          SizedBox(height: 5),
          Expanded(
              child: Align(
                  alignment: Alignment.topRight,
                  child: MediumText(text: whenText, color: NextSenseColors.blue)))
        ]);

    return Container(
        height: 125,
        child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: InkWell(
              onTap: () => onTap(context, task),
              child: RoundedBackground(child: row),
            )));
  }
}