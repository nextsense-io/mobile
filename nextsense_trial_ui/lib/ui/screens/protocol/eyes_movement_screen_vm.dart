import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:wakelock/wakelock.dart';

enum EyesMovementState {
  NOT_RUNNING,
  REST,  // Rest period.
  BLACK_SCREEN,  // Show black screen between activities.
  BLINK,  // Blink eyes.
  MOVE_RIGHT_LEFT,  // Moves eyes back and forth horizontally.
  MOVE_LEFT_RIGHT,  // Moves eyes back and forth horizontally.
  MOVE_UP_DOWN,  // Moves eyes back and forth vertically.
  MOVE_DOWN_UP,  // Moves eyes back and forth vertically.
}

class EyesMovementProtocolScreenViewModel extends ProtocolScreenViewModel {

  static final ProtocolPart _rest = ProtocolPart(
      state: EyesMovementState.REST.name,
      duration: Duration(seconds: 15),
      text: "REST",
      marker: "REST");
  static final ProtocolPart _blackScreen = ProtocolPart(
      state: EyesMovementState.BLACK_SCREEN.name,
      duration: Duration(seconds: 5));
  static final ProtocolPart _blink = ProtocolPart(
      state: EyesMovementState.BLINK.name,
      duration: Duration(seconds: 10),
      text: "10 x BLINK",
      marker: "BLINKS");
  static final ProtocolPart _rightLeft = ProtocolPart(
      state: EyesMovementState.MOVE_RIGHT_LEFT.name,
      duration: Duration(seconds: 10),
      text: "5 x RIGHT-LEFT",
      marker: "HEOG");
  static final ProtocolPart _leftRight = ProtocolPart(
      state: EyesMovementState.MOVE_LEFT_RIGHT.name,
      duration: Duration(seconds: 10),
      text: "5 x LEFT-RIGHT",
      marker: "HEOG");
  static final ProtocolPart _upDown = ProtocolPart(
      state: EyesMovementState.MOVE_UP_DOWN.name,
      duration: Duration(seconds: 10),
      text: "5 x UP-DOWN",
      marker: "VEOG");
  static final ProtocolPart _downUp = ProtocolPart(
      state: EyesMovementState.MOVE_DOWN_UP.name,
      duration: Duration(seconds: 10),
      text: "5 x DOWN-UP",
      marker: "VEOG");
  static final List<ProtocolPart> _block = [_rest, _blink, _blackScreen,
  _leftRight, _blackScreen, _upDown, _blackScreen, _rest, _blink,
  _blackScreen, _rightLeft, _blackScreen, _downUp, _blackScreen];

  final List<ScheduledProtocolPart> _scheduledProtocolParts = [];

  int _currentProtocolPart = 0;
  Duration _repetitionTime = Duration(seconds: 0);

  EyesMovementProtocolScreenViewModel(RunnableProtocol runnableProtocol) :
        super(runnableProtocol) {
    for (ProtocolPart part in _block) {
      _scheduledProtocolParts.add(ScheduledProtocolPart(protocolPart: part,
          relativeSeconds: _repetitionTime.inSeconds));
      _repetitionTime += part.duration;
    }
  }

  @override
  void onTimerStart() {
    Wakelock.enable();
    super.onTimerStart();
  }

  @override
  void onTimerFinished() {
    super.onTimerFinished();
    Wakelock.disable();
  }

  @override
  void onTimerTick(int secondsElapsed) {
    bool advanceProtocol = false;
    int blockSecondsElapsed = secondsElapsed % _repetitionTime.inSeconds;
    if (blockSecondsElapsed == 0) {
      // Start of a repetition, reset the block index and finish the current
      // step.
      if (_currentProtocolPart != 0) {
        // if (_scheduledProtocolParts[_currentProtocolPart]
        //     .protocolPart.marker != null) {
        //   _protocolStatus.endEvent();
        // }
        advanceProtocol = true;
      }
      _currentProtocolPart = 0;
    }
    // Check if can advance the index to the next part.
    if (_currentProtocolPart < _scheduledProtocolParts.length - 1) {
      if (blockSecondsElapsed >=
          _scheduledProtocolParts[_currentProtocolPart + 1].relativeSeconds) {
        // if (_scheduledProtocolParts[_currentProtocolPart]
        //     .protocolPart.marker != null) {
        //   _protocolStatus.endEvent();
        // }
        ++_currentProtocolPart;
        advanceProtocol = true;
      }
    }
    if (advanceProtocol) {
      // String currentMarker = _scheduledProtocolParts[_currentProtocolPart]
      //     .protocolPart.marker;
      // if (currentMarker != null) {
      //   _protocolStatus.startEvent(currentMarker);
      // }
    }
  }

  ProtocolPart getCurrentProtocolPart() {
    return _scheduledProtocolParts[_currentProtocolPart].protocolPart;
  }
}