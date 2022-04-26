import 'package:intl/intl.dart';

extension DateUtils on DateTime {

  static final DateFormat _hhmmFormatter = new DateFormat('HH:mm');

  // Returns hours and minutes of DateTime in 'hh:mm' format
  String get hhmm {
    try {
      return _hhmmFormatter.format(this);
    } catch (e) {
      return "";
    }
  }

  static final DateFormat _dateTimeStringFormatter =
      new DateFormat('yyyy_MM_dd_HH_mm_ss');

  String get datetime_string {
    try {
      return _dateTimeStringFormatter.format(this);
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