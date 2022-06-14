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
    super.init();
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
    _seizures!.sort((a, b) {
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