import 'package:lucid_reality/domain/dream_journal.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';

import 'dream_confirmation_screen.dart';

class DreamJournalViewModel extends RealityCheckBaseViewModel {
  final List<DreamJournal> dreamJournalList = List.empty(growable: true);

  @override
  void init() async {
    super.init();
    _fetchDreamJournals();
    lucidManager.newDreamJournalCreatedNotifier.addListener(
      () {
        _fetchDreamJournals();
      },
    );
  }

  void _fetchDreamJournals() async {
    setBusy(true);
    // Clear data if exist
    if (dreamJournalList.isNotEmpty) {
      dreamJournalList.clear();
    }
    dreamJournalList.addAll(await lucidManager.fetchDreamJournals());
    setBusy(false);
  }

  void prepareDreamJournalDummyData() {
    final dreamJournal = DreamJournal();
    dreamJournal.setCreatedAt(DateTime.now().millisecondsSinceEpoch);
    dreamJournal.setTitle("Title");
    dreamJournal.setDescription('Description');
    for (int i = 0; i <= 5; i++) {
      dreamJournalList.add(dreamJournal);
    }
    notifyListeners();
  }

  void navigateToDreamConfirmationScreen() {
    navigation.navigateTo(DreamConfirmationScreen.id);
  }
}
