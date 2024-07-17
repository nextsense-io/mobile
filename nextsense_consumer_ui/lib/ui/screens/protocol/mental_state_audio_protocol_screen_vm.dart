import 'package:flutter_common/managers/audio_manager.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/managers/mental_state_manager.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/protocol_screen_vm.dart';

class MentalStateAudioProtocolScreenViewModel extends ProtocolScreenViewModel {
  MentalStateAudioProtocolScreenViewModel(super.protocol);

  static const String _eoecTransitionSound =
      "packages/nextsense_consumer_ui/assets/sounds/eoec_transition.wav";

  final AudioManager _audioManager = getIt<AudioManager>();
  final MentalStateManager _mentalStateManager = getIt<MentalStateManager>();
  final _logger = Logger('MentalStateAudioProtocolScreenViewModel');
  final calculationEpochSecondsOptions = [9, 18, 36];

  int _eoecTransitionSoundCachedId = -1;
  double _alphaBandPower = 0;
  double _betaBandPower = 0;
  double _thetaBandPower = 0;
  double _deltaBandPower = 0;
  double _gammaBandPower = 0;
  bool _volumeRaised = false;

  Duration get calculationEpoch => _mentalStateManager.calculationEpoch;
  double get alphaBandPower => _alphaBandPower;
  double get betaBandPower => _betaBandPower;
  double get thetaBandPower => _thetaBandPower;
  double get deltaBandPower => _deltaBandPower;
  double get gammaBandPower => _gammaBandPower;
  Map<Band, List<double>?> get bandPowers => _mentalStateManager.bandPowers;
  double get powerLineFrequency => _mentalStateManager.powerLineFrequency;
  RatioIncreaseType get increaseType => _mentalStateManager.increaseType;
  set increaseType(RatioIncreaseType value) => _mentalStateManager.increaseType = value;
  double get alphaBetaRatioIncrease => _mentalStateManager.relaxedAlphaRatioIncrease;
  set alphaBetaRatioIncrease(double value) {
    _mentalStateManager.setRelaxedAlphaRatioIncrease(value);
    notifyListeners();
  }
  double get alphaBetaRatioIncreasePercentage =>
      _mentalStateManager.relaxedAlphaRatioIncreasePercentage;
  set alphaBetaRatioIncreasePercentage(double value) {
    _mentalStateManager.setRelaxedAlphaRatioIncreasePercentage(value);
    notifyListeners();
  }

  @override
  void init() async {
    super.init();
    _eoecTransitionSoundCachedId = await _audioManager.cacheAudioFile(_eoecTransitionSound);
  }

  @override
  Future<bool> startSession() async {
    NextsenseBase.connectAiroha();
    bool started = await super.startSession();
    if (!started) {
      return false;
    }
    NextsenseBase.setAirohaEq([-10,-10,-10,-10,0,0,0,0,0,0]);
    FlutterVolumeController.lowerVolume(0.2);
    _mentalStateManager.startMentalStateChecks();
    _mentalStateManager.addListener(_onMentalStateChange);
    _volumeRaised = false;
    return true;
  }

  MentalState getMentalState() {
    _logger.log(Level.INFO, "Getting mental state.");
    _alphaBandPower = _mentalStateManager.alphaBandPower;
    _betaBandPower = _mentalStateManager.betaBandPower;
    _thetaBandPower = _mentalStateManager.thetaBandPower;
    _deltaBandPower = _mentalStateManager.deltaBandPower;
    _gammaBandPower = _mentalStateManager.gammaBandPower;
    return _mentalStateManager.mentalState;
  }

  @override
  Future stopSession() async {
    await super.stopSession();
    _mentalStateManager.removeListener(_onMentalStateChange);
    _mentalStateManager.stopCalculatingMentalStates();
  }

  @override
  void onAdvanceProtocol() {
    _logger.log(Level.INFO, "Advancing protocol.");
  }

  void changeCalculationEpoch(Duration value) {
    _mentalStateManager.changeCalculationEpoch(value);
    notifyListeners();
  }

  void _onMentalStateChange() {
    switch (getMentalState()) {
      case MentalState.alert:
      // _audioManager.playAudioFile(_eoecTransitionSoundCachedId);
        break;
      case MentalState.relaxed:
        NextsenseBase.setAirohaEq([10,10,10,10,0,0,0,0,0,0]);
        if (!_volumeRaised) {
          FlutterVolumeController.raiseVolume(0.2);
          _volumeRaised = true;
        }
        // _audioManager.playAudioFile(_eoecTransitionSoundCachedId);
        break;
      case MentalState.unknown:
        break;
    }
    _logger.log(Level.INFO, "Advancing protocol.");
    notifyListeners();
  }

  @override
  void onAdvanceProtocolBlock() {
    _logger.log(Level.INFO, "Advancing protocol block.");
    _audioManager.playAudioFile(_eoecTransitionSoundCachedId);
  }
}