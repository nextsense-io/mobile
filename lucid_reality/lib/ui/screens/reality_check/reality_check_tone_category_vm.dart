import 'package:lucid_reality/domain/tone_category.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_tone_selection_screen.dart';

import 'reality_check_bedtime_screen.dart';

const totemSoundKey = 'totemSound';
const isStartForResultKey = 'isStartForResult';

class RealityCheckToneCategoryViewModel extends RealityCheckBaseViewModel {
  final List<ToneCategory> toneCategories = List.empty(growable: true);
  int selectedIndexCategory = 0;

  @override
  void init() {
    super.init();
    prepareToneCategory();
  }

  void navigateToToneSelectionScreen(ToneCategory toneCategory, bool isStartForResult) async {
    final result = await navigation.navigateTo(
      RealityCheckToneSelectionScreen.id,
      arguments: Map.fromEntries([
        MapEntry(totemSoundKey, toneCategory.totemSound),
        MapEntry(isStartForResultKey, isStartForResult)
      ]),
    );
    if (result is Tone) {
      toneCategory.totemSound = result.tone;
      toneCategory.type = result.getFileExtension();
      notifyListeners();
    }
  }

  void navigateToBedtimeScreen() {
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
    final indexAt = toneCategories.indexWhere(
        (element) => element.name == lucidManager.realityCheck.getRealityTest()?.getName());
    if (indexAt != -1) {
      var totemSound = lucidManager.realityCheck.getRealityTest()?.getTotemSound();
      if (totemSound is String) {
        toneCategories[indexAt].totemSound = totemSound;
      }
      onCategoryIndexChanged(indexAt);
    }
  }

  void onCategoryIndexChanged(int index) {
    selectedIndexCategory = index;
    notifyListeners();
  }
}
