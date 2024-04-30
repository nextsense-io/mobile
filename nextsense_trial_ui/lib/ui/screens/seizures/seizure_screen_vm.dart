import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/seizure.dart';
import 'package:nextsense_trial_ui/managers/seizures_manager.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';

class SeizureScreenViewModel extends ViewModel {
  final SeizuresManager _seizuresManager = getIt<SeizuresManager>();

  String? _seizureId;
  DateTime _seizureDate = DateTime.now();
  TimeOfDay _seizureTime = TimeOfDay.now();
  List<dynamic> triggers = [];
  String note = '';
  bool updateMode = false;

  void initWithSeizure(Seizure? seizure) {
    if (seizure != null) {
      _seizureId = seizure.id;
      _seizureDate = DateTime(seizure.getStartDateTime()!.year, seizure.getStartDateTime()!.month,
          seizure.getStartDateTime()!.day);
      _seizureTime = TimeOfDay(hour: seizure.getStartDateTime()!.hour,
          minute: seizure.getStartDateTime()!.minute);
      triggers = seizure.getTriggers();
      note = seizure.getUserNotes();
      updateMode = true;
    }
  }

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

  Future<bool> saveSeizure() async {
    setBusy(true);
    DateTime seizureDateTime = DateTime(_seizureDate.year, _seizureDate.month, _seizureDate.day,
        _seizureTime.hour, _seizureTime.minute);
    bool saved = false;
    if (updateMode) {
      saved = await _seizuresManager.updateSeizure(seizureId: _seizureId, startTime: seizureDateTime,
          triggers: List<String>.from(triggers), userNotes: note);
    } else {
      saved = await _seizuresManager.addSeizure(startTime: seizureDateTime,
          triggers: List<String>.from(triggers), userNotes: note);

    }
    setBusy(false);
    return saved;
  }
}