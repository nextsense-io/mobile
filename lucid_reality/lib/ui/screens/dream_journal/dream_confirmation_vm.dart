import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/ui/screens/dream_journal/record_your_dream_screen.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';

class DreamConfirmationViewModel extends ViewModel {
  final Navigation _navigation = getIt<Navigation>();

  void goBack() {
    _navigation.pop();
  }

  void navigateToDreamYourRecordScreen(int selected) {
    _navigation.navigateTo(RecordYourDreamScreen.id, arguments: selected);
  }
}
