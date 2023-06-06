// Generic task that can be done by the user and displayed in the UI.
import 'package:flutter/material.dart';

enum TaskType {
  survey,
  recording,
  medication,
  any
}

abstract class Task {
  String get title;
  String get intro;
  Duration? get duration;
  DateTime? get startDate;
  TimeOfDay get windowStartTime;
  TimeOfDay? get windowEndTime;
  bool get completed;
  bool get skipped;
  TaskType get type;
}