import 'package:flutter_common/utils/signal_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  test("Empty series returns false", () {
    expect(SignalUtils.isSignalFlat(signal: [], maxValue: 10, thresholdPercent: 90), false);
  });

  test("medium signal returns false", () {
    expect(SignalUtils.isSignalFlat(signal: [4, 5, 6], maxValue: 10, thresholdPercent: 90), false);
  });

  test("high flat signal returns true", () {
    expect(SignalUtils.isSignalFlat(signal: [10, 9, 8.1], maxValue: 10, thresholdPercent: 90),
        true);
  });

  test("low flat signal returns true", () {
    expect(SignalUtils.isSignalFlat(signal: [-10, -9, -8.1], maxValue: 10, thresholdPercent: 90),
        true);
  });

  test("high varied signal returns false", () {
    expect(SignalUtils.isSignalFlat(signal: [10, 5, 9.5], maxValue: 10, thresholdPercent: 90),
        false);
  });

  test("low varied signal returns false", () {
    expect(SignalUtils.isSignalFlat(signal: [-10, -5, -9.5], maxValue: 10, thresholdPercent: 90),
        false);
  });

  test("mid flat signal returns false", () {
    expect(SignalUtils.isSignalFlat(signal: [0, 0, 0], maxValue: 10, thresholdPercent: 90), false);
  });
}