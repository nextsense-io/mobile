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
}