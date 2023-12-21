import 'package:lucid_reality/domain/tone_category.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_tone_selection_screen.dart';

import 'reality_check_bedtime_screen.dart';

class RealityCheckToneCategoryViewModel extends RealityCheckBaseViewModel {
  final List<ToneCategory> toneCategories = List.empty(growable: true);

  @override
  void init() {
    prepareToneCategory();
    super.init();
  }

  void navigateToToneSelectionScreen(ToneCategory toneCategory) async {
    final result = await navigation.navigateTo(RealityCheckToneSelectionScreen.id);
    if (result is Tone) {
      toneCategory.totemSound = result.tone;
      toneCategory.type = result.getFileExtension();
      notifyListeners();
    }
  }

  void navigateToBedtimeScreen() {
    lucidManager.saveRealityTest(
        toneCategories.firstWhere((element) => element.isSelected).toRealityTest());
    navigation.navigateTo(RealityCheckBedtimeScreen.id, replace: true);
  }

  void prepareToneCategory() {
    toneCategories.add(ToneCategory("BREATHE", "Can you hold your nose and mouth shut and breathe?",
        "AIR", "m4r", "rt1", "breathe"));
    toneCategories.add(ToneCategory("READ", "Can you read this sentence twice without it changing?",
        "KYOTO", "m4r", "rt2", "read"));
    toneCategories.add(ToneCategory(
        "TIME", "Can you read a clock face or digital watch?", "TOTEM", "m4r", "rt3", "time"));
    toneCategories.add(ToneCategory(
        "HAND", "Can you push your hand through a solid surface?", "PEBBLE", "m4r", "rt4", "Hand"));
    toneCategories.add(ToneCategory("MATH", "Can you add 4 + 4?", "TEMPLE", "m4r", "rt5", "Maths"));
  }
}
