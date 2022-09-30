import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';

Theme _getDateTimePickerTheme(BuildContext context, Widget child) {
  return Theme(
    data: Theme.of(context).copyWith(
      colorScheme: ColorScheme.light(
        primary: NextSenseColors.lightGrey, // header background color
        onPrimary: NextSenseColors.purple, // header text color
        onSurface: NextSenseColors.purple, // body text color
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NextSenseColors.purple, // button text color
        ),
      ),
    ),
    child: child,
  );
}

Future<DateTime?> showThemedDateTimePicker(
    {required BuildContext context, DateTime? initialDate}) async {
  return await showDatePicker(
    context: context,
    firstDate: DateTime(2022),
    lastDate: DateTime.now(),
    initialDate: initialDate ?? DateTime.now(),
    builder: (context, child) {return _getDateTimePickerTheme(context, child!);},
  );
}

Future<TimeOfDay?> showThemedTimePicker(
    {required BuildContext context, TimeOfDay? initialTime}) async {
  return await showTimePicker(
    context: context,
    initialTime: initialTime ?? TimeOfDay.now(),
    builder: (context, child) {return _getDateTimePickerTheme(context, child!);},
  );
}