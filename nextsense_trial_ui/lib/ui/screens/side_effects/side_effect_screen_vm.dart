import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/side_effect.dart';
import 'package:nextsense_trial_ui/managers/side_effects_manager.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';

class SideEffectScreenViewModel extends ViewModel {
  final SideEffectsManager _sideEffectsManager = getIt<SideEffectsManager>();

  String? _sideEffectId;
  DateTime _sideEffectDate = DateTime.now();
  TimeOfDay _sideEffectTime = TimeOfDay.now();
  List<dynamic> sideEffectTypes = [];
  String note = '';
  bool updateMode = false;

  void initWithSideEffect(SideEffect? sideEffect) {
    if (sideEffect != null) {
      _sideEffectId = sideEffect.id;
      _sideEffectDate = DateTime(sideEffect.getStartDateTime()!.year,
          sideEffect.getStartDateTime()!.month, sideEffect.getStartDateTime()!.day);
      _sideEffectTime = TimeOfDay(
          hour: sideEffect.getStartDateTime()!.hour, minute: sideEffect.getStartDateTime()!.minute);
      sideEffectTypes = sideEffect.getSideEffectTypes();
      note = sideEffect.getUserNotes();
      updateMode = true;
    }
  }

  changeSideEffectDate(DateTime? sideEffectDate) {
    if (sideEffectDate == null) {
      return;
    }
    _sideEffectDate = sideEffectDate;
    notifyListeners();
  }

  DateTime getSideEffectDate() {
    return _sideEffectDate;
  }

  changeSideEffectTime(TimeOfDay? sideEffectTime) {
    if (sideEffectTime == null) {
      return;
    }
    _sideEffectTime = sideEffectTime;
    notifyListeners();
  }

  TimeOfDay getSideEffectTime() {
    return _sideEffectTime;
  }

  Future<bool> saveSideEffect() async {
    setBusy(true);
    DateTime sideEffectDateTime = DateTime(_sideEffectDate.year, _sideEffectDate.month,
        _sideEffectDate.day, _sideEffectTime.hour, _sideEffectTime.minute);
    bool saved = false;
    if (updateMode) {
      saved = await _sideEffectsManager.updateSideEffect(
          sideEffectId: _sideEffectId,
          startTime: sideEffectDateTime,
          sideEffectTypes: List<String>.from(sideEffectTypes),
          userNotes: note);
    } else {
      saved = await _sideEffectsManager.addSideEffect(
          startTime: sideEffectDateTime,
          sideEffectTypes: List<String>.from(sideEffectTypes),
          userNotes: note);
    }
    setBusy(false);
    return saved;
  }
}
