
import 'package:logging/logging.dart';
import 'package:flutter_common/utils/android_logger.dart';

final CustomLogPrinter _logger = CustomLogPrinter('Utils');

Future measureTime(Future future, String name) async {
  Stopwatch stopwatch = new Stopwatch()..start();
  dynamic result = await future;
  _logger.log(Level.INFO, "$name loaded in " +
      '${stopwatch.elapsedMicroseconds / 1000000.0} sec');
  return result;
}

extension StringCasingExtension on String {
  String toCapitalized() => length > 0 ?'${this[0].toUpperCase()}${substring(1).toLowerCase()}':'';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');
}