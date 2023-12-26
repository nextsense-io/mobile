import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/domain/dream_journal.dart';

class DreamJournalViewModel extends ViewModel {
  final List<DreamJournal> dreamJournalList = List.empty(growable: true);

  @override
  void init() {
    prepareDreamJournalDummyData();
    super.init();
  }

  void prepareDreamJournalDummyData() {
    final dreamJournal = DreamJournal();
    dreamJournal.setCreatedAt(DateTime.now().millisecondsSinceEpoch);
    dreamJournal.setTitle("title");
    dreamJournal.setDescription('description');
    for (int i = 0; i <= 5; i++) {
      dreamJournalList.add(dreamJournal);
    }
    notifyListeners();
  }
}
