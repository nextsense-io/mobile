import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/ui/screens/signal/signal_monitoring_screen_vm.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';

class VisualizationSettingsScreenViewModel extends ViewModel {

  static const SignalProcessing defaultSignalProcessing = SignalProcessing.filtered;
  static const double defaultLowCutFreqHzMin = 0.1;
  static const double defaultLowCutFreqHz = 1;
  static const double defaultHighCutFreqHzMax = 100;
  static const double defaultHighCutFreqHz = 55;
  static const double defaultPowerLineFrequency = 60;
  static const List<double> powerLineFrequencies = [50.0, 60.0];

  static const double _minBandwidthHz = 4;

  final _preferences = getIt<Preferences>();

  SignalProcessing _signalProcessingType = SignalProcessing.filtered;
  double _powerLineFrequency = defaultPowerLineFrequency;
  double _lowCutFrequency = defaultLowCutFreqHz;
  double _highCutFrequency = defaultHighCutFreqHz;
  double? _lowCutFrequencyMax;
  double? _highCutFrequencyMin;

  SignalProcessing get signalProcessingType => _signalProcessingType;
  double? get powerLineFrequency => _powerLineFrequency;
  double? get lowCutFrequency => _lowCutFrequency;
  double? get highCutFrequency => _highCutFrequency;
  double? get lowCutFrequencyMax => _lowCutFrequencyMax;
  double? get highCutFrequencyMin => _highCutFrequencyMin;

  @override
  void init() async {
    super.init();
    _signalProcessingType = SignalProcessing.create(
        _preferences.getString(PreferenceKey.eegSignalFilterType));
    _powerLineFrequency =
        _preferences.getDouble(PreferenceKey.powerLineFrequency) ?? defaultPowerLineFrequency;
    setLowCutFrequency(_preferences.getDouble(PreferenceKey.lowCutFrequency) ??
        defaultLowCutFreqHz);
    setHighCutFrequency(_preferences.getDouble(PreferenceKey.highCutFrequency) ??
        defaultHighCutFreqHz);
  }

  void setPowerLineFrequency(double value) {
    _powerLineFrequency = value;
    _preferences.setDouble(PreferenceKey.powerLineFrequency, value);
    notifyListeners();
  }

  void setLowCutFrequency(double value) {
    _lowCutFrequency = value;
    _highCutFrequencyMin = _lowCutFrequency + _minBandwidthHz;
    _preferences.setDouble(PreferenceKey.lowCutFrequency, value);
    notifyListeners();
  }

  void setHighCutFrequency(double value) {
    _highCutFrequency = value;
    _lowCutFrequencyMax = _highCutFrequency - _minBandwidthHz;
    _preferences.setDouble(PreferenceKey.highCutFrequency, value);
    notifyListeners();
  }

  void setSignalProcessingType(SignalProcessing? value) {
    if (value == null) {
      return;
    }
    _signalProcessingType = value;
    _preferences.setString(PreferenceKey.eegSignalFilterType, value.name);
    notifyListeners();
  }
}