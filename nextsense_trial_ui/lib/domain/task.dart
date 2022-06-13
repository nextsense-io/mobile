// Generic task that can be done by the user and displayed in the UI.
import 'package:flutter/material.dart';

abstract class Task {
  String get title;
  String get intro;
  Duration? get duration;
  TimeOfDay get windowStartTime;
  TimeOfDay? get windowEndTime;
  bool get completed;
}