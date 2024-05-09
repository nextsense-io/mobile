import 'package:flutter_common/managers/audio_manager.dart';
import 'package:logging/logging.dart';
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

  int _eoecTransitionSoundCachedId = -1;
  double _alphaBandPower = 0;
  double _betaBandPower = 0;
  double _thetaBandPower = 0;
  double _deltaBandPower = 0;
  double _gammaBandPower = 0;

  double get alphaBandPower => _alphaBandPower;
  double get betaBandPower => _betaBandPower;
  double get thetaBandPower => _thetaBandPower;
  double get deltaBandPower => _deltaBandPower;
  double get gammaBandPower => _gammaBandPower;
  double get powerLineFrequency => _mentalStateManager.powerLineFrequency;

  @override
  void init() async {
    super.init();
    _eoecTransitionSoundCachedId = await _audioManager.cacheAudioFile(_eoecTransitionSound);
  }

  @override
  Future<bool> startSession() async {
    bool started = await super.startSession();
    if (!started) {
      return false;
    }
    _mentalStateManager.startMentalStateChecks();
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
    _mentalStateManager.stopCalculatingMentalStates();
  }

  @override
  void onAdvanceProtocol() {
    switch (getMentalState()) {
      case MentalState.alert:
        // _audioManager.playAudioFile(_eoecTransitionSoundCachedId);
        break;
      case MentalState.relaxed:
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