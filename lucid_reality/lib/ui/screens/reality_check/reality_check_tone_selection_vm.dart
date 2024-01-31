import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:lucid_reality/domain/tone_category.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';
import 'package:lucid_reality/utils/utils.dart';

class RealityCheckToneSelectionViewModel extends RealityCheckBaseViewModel {
  final List<Tone> toneList = List.empty(growable: true);
  ToneCategory? toneCategory;

  @override
  void init() async {
    prepareToneList();
    super.init();
  }

  void prepareToneList() {
    toneList.add(Tone('AIR', 'AIR.mp3'));
    toneList.add(Tone('AWAKENING', 'AWAKENING.mp3'));
    toneList.add(Tone('BRUSH', 'BRUSH.mp3'));
    toneList.add(Tone('CUTE', 'CUTE.mp3'));
    toneList.add(Tone('DEW', 'DEW.mp3'));
    toneList.add(Tone('FADE', 'FADE.mp3'));
    toneList.add(Tone('GINZA', 'GINZA.mp3'));
    toneList.add(Tone('GOLD', 'GOLD.mp3'));
    toneList.add(Tone('GOZAIMASU', 'GOZAIMASU.mp3'));
    toneList.add(Tone('GOZAIMASUL', 'GOZAIMASUL.mp3'));
    toneList.add(Tone('HARAJUKU', 'HARAJUKU.mp3'));
    toneList.add(Tone('HELLO', 'HELLO.mp3'));
    toneList.add(Tone('JFK', 'JFK.mp3'));
    toneList.add(Tone('JFKL', 'JFKL.mp3'));
    toneList.add(Tone('KYOTO', 'KYOTO.mp3'));
    toneList.add(Tone('MALLET', 'MALLET.mp3'));
    toneList.add(Tone('NARITA', 'NARITA.mp3'));
    toneList.add(Tone('NIGHT', 'NIGHT.mp3'));
    toneList.add(Tone('PEBBLE', 'PEBBLE.mp3'));
    toneList.add(Tone('POND', 'POND.mp3'));
    toneList.add(Tone('PRIME', 'PRIME.mp3'));
    toneList.add(Tone('REQUEST', 'REQUEST.mp3'));
    toneList.add(Tone('SANSKRIT', 'SANSKRIT.mp3'));
    toneList.add(Tone('SAVANNA', 'SAVANNA.mp3'));
    toneList.add(Tone('SHINJUKU', 'SHINJUKU.mp3'));
    toneList.add(Tone('SHRINE', 'SHRINE.mp3'));
    toneList.add(Tone('SILVER', 'SILVER.mp3'));
    toneList.add(Tone('SUNDIAL', 'SUNDIAL.mp3'));
    toneList.add(Tone('TEMPLE', 'TEMPLE.mp3'));
    toneList.add(Tone('TIMBUKTU', 'TIMBUKTU.mp3'));
    toneList.add(Tone('TOKYO HI', 'TOKYO_HI.mp3'));
    toneList.add(Tone('TOKYO LO', 'TOKYO_LO.mp3'));
    toneList.add(Tone('TOTEM', 'TOTEM.mp3'));
    toneList.add(Tone('TWIGS', 'TWIGS.mp3'));
    toneList.add(Tone('WOOD', 'WOOD.mp3'));
    toneList.add(Tone('ZEN', 'ZEN.mp3'));
    toneList.add(Tone('ZEN LO', 'ZEN_LO.mp3'));
  }

  void playMusic(String musicFile) async {
    try {
      AssetsAudioPlayer.playAndForget(
        Audio(soundBasePath.plus(musicFile)),
      );
    } catch (t) {
      //mp3 unreachable
    }
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
