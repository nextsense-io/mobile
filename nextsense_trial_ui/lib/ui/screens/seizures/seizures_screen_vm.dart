import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/seizure.dart';
import 'package:nextsense_trial_ui/managers/seizures_manager.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class SeizuresScreenViewModel extends ViewModel {
  final SeizuresManager _seizuresManager = getIt<SeizuresManager>();

  List<Seizure>? _seizures;

  @override
  void init() async {
    setBusy(true);
    await _loadSeizures();
    setBusy(false);
    setInitialised(true);
  }

  List<Seizure>? getSeizures() {
    return _seizures;
  }

  Future<bool> deleteSeizure(Seizure seizure) async {
    setBusy(true);
    bool deleted = await _seizuresManager.deleteSeizure(seizure);
    if (deleted) {
      await _loadSeizures();
      notifyListeners();
    }
    setBusy(false);
    return deleted;
  }

  Future _loadSeizures() async {
    _seizures = await _seizuresManager.getSeizures();
    // Reverse sort order (newer first).
    _seizures!.sort((a, b) => b.getStartDateTime()!.compareTo(a.getStartDateTime()!));
  }
}