import 'package:lucid_reality/domain/tone_category.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';

class RealityCheckToneSelectionViewModel extends RealityCheckBaseViewModel {
  final List<Tone> toneList = List.empty(growable: true);
  ToneCategory? toneCategory;

  @override
  void init() async {
    prepareToneList();
    super.init();
  }

  void prepareToneList() {
    toneList.add(Tone('AIR', 'air.mp3'));
    toneList.add(Tone('AWAKENING', 'awakening.mp3'));
    toneList.add(Tone('BRUSH', 'brush.mp3'));
    toneList.add(Tone('CUTE', 'cute.mp3'));
    toneList.add(Tone('DEW', 'dew.mp3'));
    toneList.add(Tone('FADE', 'fade.mp3'));
    toneList.add(Tone('GINZA', 'ginza.mp3'));
    toneList.add(Tone('GOLD', 'gold.mp3'));
    toneList.add(Tone('GOZAIMASU', 'gozaimasu.mp3'));
    toneList.add(Tone('GOZAIMASUL', 'gozaimasul.mp3'));
    toneList.add(Tone('HARAJUKU', 'harajuku.mp3'));
    toneList.add(Tone('HELLO', 'hello.mp3'));
    toneList.add(Tone('JFK', 'jfk.mp3'));
    toneList.add(Tone('JFKL', 'jfkl.mp3'));
    toneList.add(Tone('KYOTO', 'kyoto.mp3'));
    toneList.add(Tone('MALLET', 'mallet.mp3'));
    toneList.add(Tone('NARITA', 'narita.mp3'));
    toneList.add(Tone('NIGHT', 'night.mp3'));
    toneList.add(Tone('PEBBLE', 'pebble.mp3'));
    toneList.add(Tone('POND', 'pond.mp3'));
    toneList.add(Tone('PRIME', 'prime.mp3'));
    toneList.add(Tone('REQUEST', 'request.mp3'));
    toneList.add(Tone('SANSKRIT', 'sanskrit.mp3'));
    toneList.add(Tone('SAVANNA', 'savanna.mp3'));
    toneList.add(Tone('SHINJUKU', 'shinjuku.mp3'));
    toneList.add(Tone('SHRINE', 'shrine.mp3'));
    toneList.add(Tone('SILVER', 'silver.mp3'));
    toneList.add(Tone('SUNDIAL', 'sundial.mp3'));
    toneList.add(Tone('TEMPLE', 'temple.mp3'));
    toneList.add(Tone('TIMBUKTU', 'timbuktu.mp3'));
    toneList.add(Tone('TOKYO HI', 'tokyo_hi.mp3'));
    toneList.add(Tone('TOKYO LO', 'tokyo_lo.mp3'));
    toneList.add(Tone('TOTEM', 'totem.mp3'));
    toneList.add(Tone('TWIGS', 'twigs.mp3'));
    toneList.add(Tone('WOOD', 'wood.mp3'));
    toneList.add(Tone('ZEN', 'zen.mp3'));
    toneList.add(Tone('ZEN LO', 'zen_lo.mp3'));
  }

  @override
  void goBack() async {
    setBusy(true);
    var tone = toneList.firstWhere((element) => element.isSelected);
    if (toneCategory != null) {
      toneCategory!.totemSound = tone.tone;
      toneCategory!.type = tone.getFileExtension();
      await saveRealityTest(toneCategory!.toRealityTest());
      await scheduleNewToneNotifications(tone.tone);
    }
    setBusy(false);
    navigation.popWithResult(toneList.firstWhere((element) => element.isSelected));
  }
}
