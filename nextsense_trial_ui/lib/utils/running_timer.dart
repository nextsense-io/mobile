import 'dart:async';

/*
 Simulates a timer counting the hours, minutes and seconds. The setTime method
 is called every tick interval and updates the value of the seconds, minutes and
 hours.
*/
class RunningTimer {
  final _tickInterval;

  int minutes = 0;
  int seconds = 0;
  int hours = 0;
  Function _updateStateCallback;
  Timer? _timer;

  /*
   The timer will update once every tickInterval. After each update, the
   updateStateCallback function will be called for the caller to update its
   state as needed.
   */
  RunningTimer(Duration tickInterval, Function updateStateCallback) :
      _tickInterval = tickInterval,
      _updateStateCallback = updateStateCallback {}

  resetTime() {
    this.minutes = 0;
    this.seconds = 0;
    this.hours = 0;
  }

  int getTotalSeconds() {
    return hours * 3600 + minutes * 60 + seconds;
  }

  startTimer() {
    resetTime();
    _timer = new Timer.periodic(_tickInterval, setTime);
  }

  setTime(Timer timer) {
    seconds += 1;
    if (seconds > 59) {
      seconds = 0;
      minutes += 1;
    }
    if (minutes > 59) {
      minutes = 0;
      hours += 1;
    }
    _updateStateCallback();
  }

  stop() {
    _timer?.cancel();
  }

  cancel() {
    stop();
    resetTime();
  }
}
