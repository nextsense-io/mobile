import "dart:math";

import 'package:iirjdart/butterworth.dart';

class Algorithms {
  /// Returns a [Comparator] that asserts that its first argument is comparable.
  static Comparator<T> defaultCompare<T>() =>
      (value1, value2) => (value1 as Comparable).compareTo(value2);

  // Could not find it in flutter, so imported the implementation.
  static int lowerBound<T>(List<T> sortedList, T value, {int compare(T a, T b)?}) {
    compare ??= defaultCompare<T>();
    int min = 0;
    int max = sortedList.length;
    while (min < max) {
      int mid = min + ((max - min) >> 1);
      var element = sortedList[mid];
      int comp = compare(element, value);
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return min;
  }

  // rawData: Raw data array/list
  // samplingFreq: Sampling frequency of input data in Hertz
  // lowCutFreq: Low cut frequency for highpass filter
  // highCutFreq: High cut frequency for lowpass filter
  // order: Order of filter
  static List<double> filterBandpass(
      List<double> rawData, double samplingFreq, double lowCutFreq, double highCutFreq, int order) {
    Butterworth butterworth = new Butterworth();
    double freqWidth = highCutFreq - lowCutFreq;
    butterworth.bandPass(
        order, samplingFreq, /*centerFreq=*/ lowCutFreq + freqWidth / 2, /*widthFreq=*/ freqWidth);
    List<double> filteredData = [];
    for (double sample in rawData) {
      filteredData.add(butterworth.filter(sample));
    }
    return filteredData;
  }

  static List<double> filterNotch(
      List<double> rawData, double samplingFreq, int notchFreq, int notchWidth, int order) {
    // Width of the stop band. For example, 60 Hz notch filter can have stop
    // band of 59 to 61 for notchWidth 2.
    int harmonicNotches = samplingFreq / 2 ~/ notchFreq;
    double notchWidth = 4;
    if (harmonicNotches * notchFreq + notchWidth > samplingFreq / 2) {
      --harmonicNotches;
    }
    harmonicNotches = [5, harmonicNotches].reduce(min);

    List<double> filteredData = rawData;
    for (int i = 0; i < harmonicNotches; ++i) {
      int harmonicNotchFreq = notchFreq * (i + 1);
      Butterworth butterworth = new Butterworth();
      butterworth.bandStop(order, samplingFreq, harmonicNotchFreq.toDouble(), notchWidth);
      List<double> harmonicFilteredData = [];
      for (double sample in filteredData) {
        harmonicFilteredData.add(butterworth.filter(sample));
      }
      filteredData = harmonicFilteredData;
    }
    return filteredData;
  }
}
