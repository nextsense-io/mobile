import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/domain/medication/planned_medication.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:nextsense_trial_ui/ui/components/cancel_button.dart';
import 'package:nextsense_trial_ui/ui/components/card_title_text.dart';
import 'package:nextsense_trial_ui/ui/components/content_text.dart';
import 'package:nextsense_trial_ui/ui/components/emphasized_button.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:flutter_common/ui/components/rounded_background.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';

class MedicationCard {
  final Task task;
  final VoidCallback? onTakenTap;
  final VoidCallback? onNotTakenTap;
  final String title;
  final String intro;
  final Duration? duration;
  final TimeOfDay windowStartTime;
  final TimeOfDay? windowEndTime;
  final bool completed;

  MedicationCard(
      {required Task task, required VoidCallback? onTakenTap, required VoidCallback? onNotTakenTap})
      : this.task = task,
        this.title = task.title,
        this.intro = task.intro,
        this.duration = task.duration,
        this.windowStartTime = task.windowStartTime,
        this.windowEndTime = task.windowEndTime,
        this.completed = task.completed,
        this.onTakenTap = onTakenTap,
        this.onNotTakenTap = onNotTakenTap;

  Future showExpandedMedicationDialog(BuildContext context,
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
                  CardTitleText(text: 'Medication Taken?'),
                  SizedBox(height: 15),
                  ContentText(text: 'Have you already taken this medication?',
                      color: NextSenseColors.darkBlue),
                  SizedBox(height: 15),
                  if (!completed)
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      Expanded(child: EmphasizedButton(
                          text: MediumText(text: 'Taken', color: Colors.white,
                              textAlign: TextAlign.center),
                          enabled: true,
                          onTap: onTakenTap)),
                      SizedBox(width: 10),
                      Expanded(child: EmphasizedButton(
                          text: MediumText(text: 'Not Taken', color: Colors.white,
                              textAlign: TextAlign.center),
                          enabled: true,
                          onTap: onNotTakenTap)),
                    ])
                ]))),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
        );
      },
    );
  }
}

class PlannedMedicationCard extends StatelessWidget {
  final PlannedMedication plannedMedication;

  PlannedMedicationCard(PlannedMedication plannedMedication)
      : this.plannedMedication = plannedMedication;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 120,
        child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: RoundedBackground(
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(children: [
                      Align(
                          alignment: Alignment.centerLeft,
                          child: HeaderText(
                              text: plannedMedication.name, color: NextSenseColors.darkBlue)),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: MediumText(text: plannedMedication.indication)),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: MediumText(text: plannedMedication.period.toDisplayString())),
                    ])))));
  }
}
