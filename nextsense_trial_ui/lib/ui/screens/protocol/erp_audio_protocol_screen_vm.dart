import 'dart:math';
import 'package:flutter_common/domain/firebase_entity.dart';
import 'package:flutter_common/domain/protocol.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/event.dart';
import 'package:nextsense_trial_ui/domain/session/protocol.dart';
import 'package:nextsense_trial_ui/domain/session/runnable_protocol.dart';
import 'package:nextsense_trial_ui/managers/audio_manager.dart';
import 'package:nextsense_trial_ui/managers/event_types_manager.dart';
import 'package:nextsense_trial_ui/managers/trial_ui_firestore_manager.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ERPAudioProtocolScreenViewModel extends ProtocolScreenViewModel {

  static const String _normalSound =
      "packages/nextsense_trial_ui/assets/sounds/audiobeep2_988Hz_0p1s.wav";
  static const String _oddSound =
      "packages/nextsense_trial_ui/assets/sounds/audiobeep1_350Hz_0p1s.wav";
  static const int _soundLoopCount = 5;

  final AudioManager _audioManager = getIt<AudioManager>();
  final EventTypesManager _eventTypesManager = getIt<EventTypesManager>();
  final TrialUiFirestoreManager _firestoreManager = getIt<TrialUiFirestoreManager>();
  final Random _random = Random();
  final CustomLogPrinter _logger = CustomLogPrinter('ErpAudioProtocolScreenViewModel');

  int _normalSoundCachedId = -1;
  int _oddSoundCachedId = -1;
  int _oddSoundIndex = -1;
  bool _lastSoundWasOdd = false;

  ERPAudioProtocolScreenViewModel(RunnableProtocol runnableProtocol) :
        super(runnableProtocol, useCountDownTimer: false);

  @override
  void init() async {
    super.init();
    _normalSoundCachedId = await _audioManager.cacheAudioFile(_normalSound);
    _oddSoundCachedId = await _audioManager.cacheAudioFile(_oddSound);
  }

  @override
  void dispose() {
    _audioManager.stopPlayingLastAudio();
    _audioManager.clearCache();
    super.dispose();
  }

  @override
  void onTimerStart() {
    WakelockPlus.enable();
    super.onTimerStart();
  }

  @override
  void onTimerFinished() {
    super.onTimerFinished();
    WakelockPlus.disable();
  }

  @override
  List<ScheduledProtocolPart> getProtocolParts() {
    List<ScheduledProtocolPart> parts = [];
    Duration repetitionTime = const Duration(seconds: 0);
    // Randomize index of odd sound. Cannot have 2 odd sounds in a row.
    if (_oddSoundIndex == _soundLoopCount - 1) {
      _oddSoundIndex = _random.nextInt(_soundLoopCount - 1) + 1;
    } else {
      _oddSoundIndex = _random.nextInt(_soundLoopCount);
    }
    int currentPartIndex = -1;
    for (ProtocolPart part in runnableProtocol.protocol.protocolBlock) {
      ++currentPartIndex;
      if (part.marker == ERPAudioState.PLAY_SOUND.name) {
        if (currentPartIndex / 3 == _oddSoundIndex) {
          parts.add(ScheduledProtocolPart(protocolPart: ERPAudioProtocol.oddSound,
              relativeMilliseconds: repetitionTime.inMilliseconds));
        } else {
          parts.add(ScheduledProtocolPart(protocolPart: ERPAudioProtocol.normalSound,
              relativeMilliseconds: repetitionTime.inMilliseconds));
        }
        repetitionTime += part.duration;
        continue;
      }
      parts.add(ScheduledProtocolPart(protocolPart: part,
          relativeMilliseconds: repetitionTime.inMilliseconds));
      repetitionTime += part.duration;
    }
    return parts;
  }

  @override
  void onAdvanceProtocol() {
    if (getScheduledProtocolParts()[currentProtocolPart].protocolPart.state ==
        ERPAudioState.NORMAL_SOUND.name) {
      _audioManager.playAudioFile(_normalSoundCachedId);
      _lastSoundWasOdd = false;
    } else if (getScheduledProtocolParts()[currentProtocolPart].protocolPart.state ==
        ERPAudioState.ODD_SOUND.name) {
      _audioManager.playAudioFile(_oddSoundCachedId);
      _lastSoundWasOdd = true;
    }
  }

  @override
  Future<bool> recordButtonPress() async {
    DateTime eventTime = DateTime.now();
    String? sessionId = runnableProtocol.lastSessionId;
    String marker = ERPAudioState.WRONG_RESPONSE.name;
    if (_lastSoundWasOdd && getCurrentProtocolPart()?.state == ERPAudioState.RESPONSE_WINDOW.name) {
      marker = ERPAudioState.CORRECT_RESPONSE.name;
    }
    if (sessionId == null) {
      _logger.log(Level.SEVERE,
          "Could not save event $marker, no session id!");
      return false;
    }
    FirebaseEntity firebaseEntity = await _firestoreManager.addAutoIdEntity(
        [Table.sessions, Table.events], [sessionId]);
    Event event = Event(firebaseEntity);
    event..setValue(EventKey.start_datetime, eventTime)
      ..setValue(EventKey.end_datetime, eventTime)
      ..setValue(EventKey.marker, marker)
      ..setValue(EventKey.type, _eventTypesManager.getEventType(marker)!.id);
    return await event.save();
  }
}