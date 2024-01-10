import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:lucid_reality/domain/tone_category.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';
import 'package:lucid_reality/utils/utils.dart';

class RealityCheckToneSelectionViewModel extends RealityCheckBaseViewModel {
  final List<Tone> toneList = List.empty(growable: true);

  @override
  void init() async {
    prepareToneList();
    super.init();
  }

  void prepareToneList() {
    toneList.add(Tone('AIR', 'AIR.m4r'));
    toneList.add(Tone('AWAKENING', 'AWAKENING.m4r'));
    toneList.add(Tone('BRUSH', 'BRUSH.m4r'));
    toneList.add(Tone('CUTE', 'CUTE.m4r'));
    toneList.add(Tone('DEW', 'DEW.m4r'));
    toneList.add(Tone('FADE', 'FADE.m4r'));
    toneList.add(Tone('GINZA', 'GINZA.m4r'));
    toneList.add(Tone('GOLD', 'GOLD.m4r'));
    toneList.add(Tone('GOZAIMASU', 'GOZAIMASU.m4r'));
    toneList.add(Tone('GOZAIMASUL', 'GOZAIMASUL.m4r'));
    toneList.add(Tone('HARAJUKU', 'HARAJUKU.m4r'));
    toneList.add(Tone('HELLO', 'HELLO.m4r'));
    toneList.add(Tone('JFK', 'JFK.m4r'));
    toneList.add(Tone('JFKL', 'JFKL.m4r'));
    toneList.add(Tone('KYOTO', 'KYOTO.m4r'));
    toneList.add(Tone('MALLET', 'MALLET.m4r'));
    toneList.add(Tone('NARITA', 'NARITA.m4r'));
    toneList.add(Tone('NIGHT', 'NIGHT.m4r'));
    toneList.add(Tone('PEBBLE', 'PEBBLE.m4r'));
    toneList.add(Tone('POND', 'POND.m4r'));
    toneList.add(Tone('PRIME', 'PRIME.m4r'));
    toneList.add(Tone('REQUEST', 'REQUEST.m4r'));
    toneList.add(Tone('SANSKRIT', 'SANSKRIT.m4r'));
    toneList.add(Tone('SAVANNA', 'SAVANNA.m4r'));
    toneList.add(Tone('SHINJUKU', 'SHINJUKU.m4r'));
    toneList.add(Tone('SHRINE', 'SHRINE.m4r'));
    toneList.add(Tone('SILVER', 'SILVER.m4r'));
    toneList.add(Tone('SUNDIAL', 'SUNDIAL.m4r'));
    toneList.add(Tone('TEMPLE', 'TEMPLE.m4r'));
    toneList.add(Tone('TIMBUKTU', 'TIMBUKTU.m4r'));
    toneList.add(Tone('TOKYO HI', 'TOKYO_HI.m4r'));
    toneList.add(Tone('TOKYO LO', 'TOKYO_LO.m4r'));
    toneList.add(Tone('TOTEM', 'TOTEM.m4r'));
    toneList.add(Tone('TWIGS', 'TWIGS.m4r'));
    toneList.add(Tone('WOOD', 'WOOD.m4r'));
    toneList.add(Tone('ZEN', 'ZEN.m4r'));
    toneList.add(Tone('ZEN LO', 'ZEN_LO.m4r'));
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
  void goBack() {
    navigation.popWithResult(toneList.firstWhere((element) => element.isSelected));
  }
}
