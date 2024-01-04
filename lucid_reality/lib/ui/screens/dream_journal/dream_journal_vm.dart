import 'dart:ui';

import 'package:lucid_reality/domain/dream_journal.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';

import 'dream_confirmation_screen.dart';
import 'record_your_dream_screen.dart';

class DreamJournalViewModel extends RealityCheckBaseViewModel {
  final List<DreamJournal> dreamJournalList = List.empty(growable: true);
  final List<DreamJournalMenu> dreamJournalMenuItem = List.empty(growable: true);

  @override
  void init() async {
    prepareDreamJournalMenuItem();
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

  void prepareDreamJournalMenuItem() {
    dreamJournalMenuItem.add(
      DreamJournalMenu(
        'Edit',
        'ic_edit.svg',
        routeName: RecordYourDreamScreen.id,
      ),
    );
    dreamJournalMenuItem.add(DreamJournalMenu(
      'Delete',
      'ic_delete_coral.svg',
      foregroundColor: NextSenseColors.coral,
    ));
  }

  void navigateToRecordYourDreamScreen(DreamJournal dreamJournal) {
    navigation.navigateTo(RecordYourDreamScreen.id, arguments: dreamJournal);
  }

  void deleteDreamJournal(DreamJournal dreamJournal) async {
    await lucidManager.deleteDreamJournal(dreamJournal);
    _fetchDreamJournals();
  }
}

class DreamJournalMenu {
  late final String _label;
  late final String _iconName;
  late final String routeName;
  late final Color foregroundColor;

  DreamJournalMenu(this._label, this._iconName,
      {this.foregroundColor = NextSenseColors.white, this.routeName = ''});

  String get iconName => _iconName;

  set iconName(String value) {
    _iconName = value;
  }

  String get label => _label;

  set label(String value) {
    _label = value;
  }
}
