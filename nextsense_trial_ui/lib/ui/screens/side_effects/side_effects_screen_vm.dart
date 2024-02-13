import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/side_effect.dart';
import 'package:nextsense_trial_ui/managers/side_effects_manager.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';

class SideEffectsScreenViewModel extends ViewModel {
  final SideEffectsManager _sideEffectsManager = getIt<SideEffectsManager>();

  List<SideEffect>? _sideEffects;

  @override
  void init() async {
    setBusy(true);
    super.init();
    await _loadSideEffects();
    setBusy(false);
    setInitialised(true);
  }

  List<SideEffect>? getSideEffects() {
    return _sideEffects;
  }

  Future<bool> deleteSideEffect(SideEffect side_effect) async {
    setBusy(true);
    bool deleted = await _sideEffectsManager.deleteSideEffect(side_effect);
    if (deleted) {
      await _loadSideEffects();
      notifyListeners();
    }
    setBusy(false);
    return deleted;
  }

  Future _loadSideEffects() async {
    _sideEffects = await _sideEffectsManager.getSideEffects();
    _sideEffects!.sort((a, b) {
      if (a.getStartDateTime() == null) {
        return -1;
      }
      if (b.getStartDateTime() == null) {
        return 1;
      }
      // Reverse sort order (newer first).
      return b.getStartDateTime()!.compareTo(a.getStartDateTime()!);
    });
  }
}