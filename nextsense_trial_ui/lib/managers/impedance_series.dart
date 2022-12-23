import 'package:nextsense_trial_ui/domain/earbud_configs.dart';
import 'package:nextsense_trial_ui/utils/algorithms.dart';

class ImpedanceData implements Comparable<ImpedanceData> {
  Map<EarLocation, double> impedances = {};
  DateTime timestamp;

  ImpedanceData({required this.impedances, required this.timestamp});

  @override
  int compareTo(ImpedanceData other) {
    return timestamp.difference(other.timestamp).inMilliseconds;
  }
}

class ImpedanceSeries {
  List<ImpedanceData> _impedanceDataList = [];

  void addImpedanceData(ImpedanceData impedanceData) {
    _impedanceDataList.add(impedanceData);
  }

  List<ImpedanceData> getImpedanceData() {
    return _impedanceDataList;
  }

  void resetImpedanceData() {
    _impedanceDataList.clear();
  }

  int getVariationAcrossTime({required EarLocation earLocation, required Duration time,
      DateTime? endTime}) {
    if (_impedanceDataList.isEmpty) {
      return -1;
    }
    DateTime startTime = endTime != null ? endTime.subtract(time) : DateTime.now().subtract(time);
    int startIndex = Algorithms.lowerBound(
        _impedanceDataList, new ImpedanceData(impedances: {},
        timestamp: startTime));
    if (startIndex == 0) {
      // First element, wait until there is more data than the time period before a calculation can
      // be done.
      return -1;
    }
    List<ImpedanceData> recentImpedanceDataList = _impedanceDataList.sublist(startIndex);
    if (recentImpedanceDataList.isEmpty) {
      return -1;
    }
    double minValue = double.maxFinite;
    double maxValue = 0;
    for (ImpedanceData data in recentImpedanceDataList) {
      if (data.impedances[earLocation]! < minValue) {
        minValue = data.impedances[earLocation]!;
      }
      if (data.impedances[earLocation]! > maxValue) {
        maxValue = data.impedances[earLocation]!;
      }
    }
    if (maxValue == 0) {
      return -1;
    }
    return ((maxValue - minValue) / maxValue * 100).round();
  }
}