import 'package:collection/collection.dart';

class SignalUtils {

  static isSignalFlat(
      {required List<double> signal, required double maxValue, required int thresholdPercent}) {
    int maxThreshold = maxValue * thresholdPercent ~/ 100;
    int minThreshold = -maxThreshold;
    if (signal.isEmpty) {
      return false;
    }
    if (signal.average > maxThreshold) {
      return true;
    }
    if (signal.average < minThreshold) {
      return true;
    }
    return false;
  }
}