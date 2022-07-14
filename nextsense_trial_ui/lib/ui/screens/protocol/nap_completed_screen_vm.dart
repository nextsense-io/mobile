import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/seizure.dart';
import 'package:nextsense_trial_ui/managers/session_manager.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class NaoCompletedScreenViewModel extends ViewModel {
  final SessionManager _sessionManager = getIt<SessionManager>();

  bool? fellAsleep;
  String? noSleepReason;
  int? sleepMinutes;
  String? arousalReason;

  DateTime _seizureDate = DateTime.now();
  TimeOfDay _seizureTime = TimeOfDay.now();
  List<dynamic> triggers = [];
  String note = '';

  changeSeizureDate(DateTime? seizureDate) {
    if (seizureDate == null) {
      return;
    }
    _seizureDate = seizureDate;
    notifyListeners();
  }

  DateTime getSeizureDate() {
    return _seizureDate;
  }

  changeSeizureTime(TimeOfDay? seizureTime) {
    if (seizureTime == null) {
      return;
    }
    _seizureTime = seizureTime;
    notifyListeners();
  }

  TimeOfDay getSeizureTime() {
    return _seizureTime;
  }

  Future<bool> saveNapData() async {
    setBusy(true);
    DateTime seizureDateTime = DateTime(_seizureDate.year, _seizureDate.month, _seizureDate.day,
        _seizureTime.hour, _seizureTime.minute);
    // bool saved = await _sessionManager.addProtocolData(startTime: seizureDateTime,
    //       triggers: List<String>.from(triggers), userNotes: note);
    setBusy(false);
    return false;
  }
}