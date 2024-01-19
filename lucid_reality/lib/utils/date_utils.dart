import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension TimeUtils on TimeOfDay {
  String get hmm {
    return '${hour.toString()}:${minute.toString().padLeft(2, '0')}';
  }

  String get hmma {
    return '$hmm${period.name}';
  }
}

extension DateUtils on DateTime {
  static final DateFormat _dateOnlyFormatter = new DateFormat('MMM d, yyyy');
  static final DateFormat _hhmmFormatter = new DateFormat('HH:mm');
  static final DateFormat _hmmFormatter = new DateFormat('h:mm');
  static final DateFormat _hmmaFormatter = new DateFormat('h:mma');
  static final DateFormat _MonthDayFormatter = new DateFormat('MMM d');
  static final DateFormat _dateTimeStringFormatter = new DateFormat('yyyy_MM_dd_HH_mm_ss');
  static final DateFormat _dateTimeHumanizedFormatter = new DateFormat('d MMM, yyyy \'at\' H:mma');

  // Returns hours and minutes of DateTime in 'hh:mm' format
  String get hhmm {
    try {
      return _hhmmFormatter.format(this);
    } catch (e) {
      return "";
    }
  }

  // Returns hours and minutes of DateTime in 'h:mma' format
  String get hmma {
    try {
      return _hmmaFormatter.format(this);
    } catch (e) {
      return "";
    }
  }

  // Returns hours and minutes of DateTime in 'h:mm' format
  String get hmm {
    try {
      return _hmmFormatter.format(this);
    } catch (e) {
      return "";
    }
  }

  // Returns date only
  String get date {
    try {
      return _dateOnlyFormatter.format(this);
    } catch (e) {
      return "";
    }
  }

  String get monthDay {
    try {
      return _MonthDayFormatter.format(this);
    } catch (e) {
      return "";
    }
  }

  String get string {
    try {
      return _dateTimeStringFormatter.format(this);
    } catch (e) {
      return "";
    }
  }

  String get humanized {
    try {
      return _dateTimeHumanizedFormatter.format(this);
    } catch (e) {
      return "";
    }
  }

  // Compare only day part of datetime, omitting hours, minutes etc.
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  // Returns closest future midnight to desired date
  DateTime get closestFutureMidnight {
    return DateTime(this.year, this.month, this.day, 23, 59, 59);
  }

  DateTime get dateNoTime {
    return DateTime(this.year, this.month, this.day);
  }

  String get dayOfWeek {
    return DateFormat('E').format(this);
  }

  String get monthString {
    return DateFormat('MMM').format(this);
  }

  DateTime addMonths(int months) {
    return DateTime(year, month + months, day);
  }

  DateTime subtractMonths(int months) {
    return DateTime(year, month + months, day);
  }
}

extension DurationUtils on Duration {
  String get hhmm {
    try {
      if (inHours == 0) {
        return "${inMinutes.remainder(60)}m";
      }
      return "${inHours}h ${inMinutes.remainder(60)}m";
    } catch (e) {
      return "N/A";
    }
  }
}

extension TimeOfDayExtension on TimeOfDay {
  int compareTo(TimeOfDay other) {
    if (hour < other.hour) return -1;
    if (hour > other.hour) return 1;
    if (minute < other.minute) return -1;
    if (minute > other.minute) return 1;
    return 0;
  }
}

extension IntToDate on int {
  DateTime toDate() => DateTime.fromMillisecondsSinceEpoch(this);
}

DateTime findFirstDateOfTheWeek(DateTime dateTime) {
  int currentDay = dateTime.weekday;
  return dateTime.subtract(Duration(days: currentDay));
}
