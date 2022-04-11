import 'package:intl/intl.dart';

extension DateUtils on DateTime {

  // Returns hours and minutes of DateTime in 'hh:mm' format
  String get hhmm {
    try {
      return DateFormat("HH:mm").format(this);
    } catch (e) {
      return "";
    }
  }

  // Compare only day part of datetime, omitting hours, minutes etc.
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month
        && day == other.day;
  }

  // Returns closest future midnight to desired date
  DateTime get closestFutureMidnight {
    return DateTime(
      this.year,
      this.month,
      this.day + 1,
    );
  }
}