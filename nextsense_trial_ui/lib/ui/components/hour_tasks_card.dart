import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/task_card.dart';

class TaskWithTap {
  final Task task;
  final VoidCallback? onTap;

  TaskWithTap(this.task, this.onTap);
}

class HourTasksCard extends StatelessWidget {
  final String time;
  final List<TaskWithTap> tasks;

  HourTasksCard({required String time, required List<TaskWithTap> tasks}) :
        this.time = time, this.tasks = tasks;

  @override
  Widget build(BuildContext context) {
    return Container(height: tasks.length * 120, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding:EdgeInsets.only(top: 22, left: 10, right: 10, bottom: 10),
            child: MediumText(text: time)),
        SizedBox(width: 10),
        Expanded(child: Column(
          children: tasks.map((task) => TaskCard(task.task, false, task.onTap)).toList()))
    ]));
  }
}