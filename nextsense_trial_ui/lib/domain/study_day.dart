import 'package:intl/intl.dart';
// Represents single day of study
class StudyDay {
  late DateTime date;

  int get dayNumber => date.day;

  StudyDay(DateTime date) {
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