import 'package:intl/intl.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';

// Represents single day of study
class StudyDay {

  // Date of study day has zero hours/minutes/seconds - 00:00:00
  late DateTime date;

  // Returns # day of study
  int dayNumber;

  int get dayOfMonth => date.day;

  // Returns closest future midnight of this study day
  // Example: For study say 2022-01-01 closest future midnight will be
  // 2022-01-02 00:00:00
  DateTime get closestFutureMidnight => date.closestFutureMidnight;

  StudyDay(DateTime date, this.dayNumber) {
    // Make sure omit hours, minutes, etc.
    this.date = DateTime(date.year, date.month, date.day);
  }

  @override
  bool operator==(Object other) {
    if (identical(this, other)) return true;
    if (!(other is StudyDay)) return false;
    return other.date.isAtSameMomentAs(date);
  }

  @override
  String toString() {
    return DateFormat('<MMMM d, y>').format(date);
  }
}