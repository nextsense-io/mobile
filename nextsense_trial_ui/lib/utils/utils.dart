
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

final CustomLogPrinter _logger = CustomLogPrinter('Utils');

Future measureTime(Future future, String name) async {
  Stopwatch stopwatch = new Stopwatch()..start();
  dynamic result = await future;
  _logger.log(Level.INFO, "$name loaded in " +
      '${stopwatch.elapsedMicroseconds / 1000000.0} sec');
  return result;
}