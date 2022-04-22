import 'package:audioplayers/audioplayers.dart';

/// Manage the single audio player for the application and the sound files cache
/// for low latency playback which is important when running protocols.
class AudioManager {
  final AudioPlayer _audioPlayer;
  late final AudioCache _cachedPlayer;

  AudioManager() : _audioPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY) {
    _cachedPlayer = AudioCache(fixedPlayer: _audioPlayer);
  }

  Future cacheAudioFile(String assetLocation) async {
    await _cachedPlayer.load(assetLocation);
  }

  Future playAudioFile(String assetLocation, {bool? loop}) async {
    if (loop != null && loop) {
      await _cachedPlayer.loop(assetLocation);
    } else {
      await _cachedPlayer.play(assetLocation);
    }
  }

  Future stopPlayingAudio() async {
    await _audioPlayer.stop();
  }

  Future clearCache() async {
    await _cachedPlayer.clearAll();
  }
}