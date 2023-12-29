import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/dream_journal.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';

import 'dream_confirmation_screen.dart';

class DreamJournalViewModel extends ViewModel {
  final Navigation _navigation = getIt<Navigation>();
  final List<DreamJournal> dreamJournalList = List.empty(growable: true);

  @override
  void init() {
    prepareDreamJournalDummyData();
    super.init();
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

  goBack() {
    _navigation.pop();
  }

  void navigateToDreamConfirmationScreen() {
    _navigation.navigateTo(DreamConfirmationScreen.id);
  }
}
