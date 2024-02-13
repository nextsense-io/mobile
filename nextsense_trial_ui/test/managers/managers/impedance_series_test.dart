import 'package:flutter_common/domain/earbuds_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_common/managers/impedance_series.dart';

void main() {
  final EarbudsConfig earBudConfig = EarbudsConfigs.getConfig('xenon_b_config');
  final EarLocation leftCanal = earBudConfig.earLocations[EarLocationName.LEFT_CANAL]!;
  final EarLocation leftHelix = earBudConfig.earLocations[EarLocationName.LEFT_HELIX]!;
  final EarLocation rightCanal = earBudConfig.earLocations[EarLocationName.RIGHT_CANAL]!;

  test("Empty series returns -1", () {
    ImpedanceSeries series = ImpedanceSeries();
    expect(series.getVariationAcrossTime(earLocation: leftCanal, time: Duration(seconds: 5)), -1);
  });

  test("Not long enough series returns -1", () {
    ImpedanceSeries series = ImpedanceSeries();
    Map<EarLocation, double> data = {leftCanal: 1000, leftHelix: 2000, rightCanal: 3000};
    series.addImpedanceData(ImpedanceData(impedances: data,
        timestamp: DateTime(2022, 1, 1, 1, 0, 59)));
    series.addImpedanceData(ImpedanceData(impedances: data,
        timestamp: DateTime(2022, 1, 1, 1, 1, 1)));
    expect(series.getVariationAcrossTime(earLocation: leftCanal, time: Duration(seconds: 5),
        endTime: DateTime(2022, 1, 1, 1, 1, 1)), -1);
  });

  test("Long enough series with no variations returns 0", () {
    ImpedanceSeries series = ImpedanceSeries();
    Map<EarLocation, double> data = {leftCanal: 1000, leftHelix: 2000, rightCanal: 3000};
    series.addImpedanceData(ImpedanceData(impedances: data,
        timestamp: DateTime(2022, 1, 1, 1, 0, 54)));
    series.addImpedanceData(ImpedanceData(impedances: data,
        timestamp: DateTime(2022, 1, 1, 1, 0, 59)));
    series.addImpedanceData(ImpedanceData(impedances: data,
        timestamp: DateTime(2022, 1, 1, 1, 1, 1)));
    expect(series.getVariationAcrossTime(earLocation: leftCanal, time: Duration(seconds: 5),
        endTime: DateTime(2022, 1, 1, 1, 1, 1)), 0);
  });

  test("Long enough increasing series returns correct variation", () {
    ImpedanceSeries series = ImpedanceSeries();
    series.addImpedanceData(ImpedanceData(
        impedances: {leftCanal: 1000, leftHelix: 2000, rightCanal: 3000},
        timestamp: DateTime(2022, 1, 1, 1, 0, 54)));
    series.addImpedanceData(ImpedanceData(
        impedances: {leftCanal: 2000, leftHelix: 2000, rightCanal: 3000},
        timestamp: DateTime(2022, 1, 1, 1, 0, 59)));
    series.addImpedanceData(ImpedanceData(
        impedances: {leftCanal: 2500, leftHelix: 2000, rightCanal: 3000},
        timestamp: DateTime(2022, 1, 1, 1, 1, 0)));
    series.addImpedanceData(ImpedanceData(
        impedances: {leftCanal: 3000, leftHelix: 2000, rightCanal: 3000},
        timestamp: DateTime(2022, 1, 1, 1, 1, 1)));
    expect(series.getVariationAcrossTime(earLocation: leftCanal, time: Duration(seconds: 5),
        endTime: DateTime(2022, 1, 1, 1, 1, 1)), 33);
  });

  test("Long enough decreasing series returns correct variation", () {
    ImpedanceSeries series = ImpedanceSeries();
    series.addImpedanceData(ImpedanceData(
        impedances: {leftCanal: 3000, leftHelix: 2000, rightCanal: 3000},
        timestamp: DateTime(2022, 1, 1, 1, 0, 54)));
    series.addImpedanceData(ImpedanceData(
        impedances: {leftCanal: 2000, leftHelix: 2000, rightCanal: 3000},
        timestamp: DateTime(2022, 1, 1, 1, 0, 59)));
    series.addImpedanceData(ImpedanceData(
        impedances: {leftCanal: 1000, leftHelix: 2000, rightCanal: 3000},
        timestamp: DateTime(2022, 1, 1, 1, 1, 0)));
    series.addImpedanceData(ImpedanceData(
        impedances: {leftCanal: 1500, leftHelix: 2000, rightCanal: 3000},
        timestamp: DateTime(2022, 1, 1, 1, 1, 1)));
    expect(series.getVariationAcrossTime(earLocation: leftCanal, time: Duration(seconds: 5),
        endTime: DateTime(2022, 1, 1, 1, 1, 1)), 50);
  });
}