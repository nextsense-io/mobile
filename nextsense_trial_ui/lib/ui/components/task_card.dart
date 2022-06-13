import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:nextsense_trial_ui/ui/components/card_title_text.dart';
import 'package:nextsense_trial_ui/ui/components/content_text.dart';
import 'package:nextsense_trial_ui/ui/components/emphasized_button.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/rounded_background.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Function onTap;
  final String title;
  final String intro;
  final Duration? duration;
  final TimeOfDay windowStartTime;
  final TimeOfDay? windowEndTime;
  final bool completed;

  TaskCard(Task task, Function onTap)
      : this.task = task,
        this.title = task.title,
        this.intro = task.intro,
        this.duration = task.duration,
        this.windowStartTime = task.windowStartTime,
        this.windowEndTime = task.windowEndTime,
        this.completed = task.completed,
        this.onTap = onTap;

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
          Column(children: [
            completed
                ? Expanded(
                    child: SvgPicture.asset('assets/images/circle_checked.svg',
                        semanticsLabel: 'completed', height: 20))
                : Expanded(
                    child: SvgPicture.asset('assets/images/circle.svg',
                        semanticsLabel: 'completed', height: 20)),
            Expanded(child: SizedBox(height: 1)),
          ]),
          SizedBox(width: 10),
          Expanded(
              child: Column(children: [
            Expanded(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Flexible(child: CardTitleText(text: title)),
                  SizedBox(width: 5),
                  if (duration != null)
                    if (showClock)
                      SvgPicture.asset('assets/images/clock.svg',
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

    return ExpandableNotifier(
        child: ExpandableTheme(
            data: ExpandableThemeData(
                hasIcon: false,
                tapBodyToExpand: true,
                tapBodyToCollapse: true,
                animationDuration: const Duration(milliseconds: 500)),
            child: ScrollOnExpand(
                child: ExpandablePanel(
                    collapsed: Container(
                        height: 115,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          child: RoundedBackground(child: row),
                        )),
                    expanded: Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        child: RoundedBackground(
                            child: Column(children: [
                          Container(height: 71, child: row),
                          SizedBox(height: 15),
                          ContentText(text: intro, color: NextSenseColors.darkBlue),
                          SizedBox(height: 15),
                          if (!completed) EmphasizedButton(
                              text: MediumText(text: 'Start', color: Colors.white), enabled: true,
                              onTap: onTap)
                        ])))))));
  }
}
