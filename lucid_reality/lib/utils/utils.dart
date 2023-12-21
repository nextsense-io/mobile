import 'package:flutter_common/utils/android_logger.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

final CustomLogPrinter _logger = CustomLogPrinter('Utils');

const String imageBasePath = "packages/lucid_reality/assets/images/";
const String soundBasePath = "packages/lucid_reality/assets/sounds/TotemSounds/";

extension StringAppend on String {
  String plus(String str) {
    return "$this$str";
  }
}

Future measureTime(Future future, String name) async {
  Stopwatch stopwatch = new Stopwatch()..start();
  dynamic result = await future;
  _logger.log(Level.INFO, "$name loaded in " + '${stopwatch.elapsedMicroseconds / 1000000.0} sec');
  return result;
}

extension StringCasingExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';

  String toTitleCase() =>
      replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');
}

extension DateTimeFormating on DateTime {
  String getDate() {
    return DateFormat('MMM d, yyyy').format(this);
  }

  String getTime() {
    return DateFormat('h:mma').format(this);
  }

  String get hms {
    return DateFormat('h:mm:ss:S').format(this);
  }
}
