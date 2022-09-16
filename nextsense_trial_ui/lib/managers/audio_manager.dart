import 'package:audioplayers/audioplayers.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

/// Manage the single audio player for the application and the sound files cache
/// for low latency playback which is important when running protocols.
class AudioManager {
  final CustomLogPrinter _logger = CustomLogPrinter('AudioManager');

  final AudioPlayer _audioPlayer;

  AudioManager() : _audioPlayer = AudioPlayer();

  Future cacheAudioFile(String assetLocation) async {
    _logger.log(Level.FINE, "Caching ${assetLocation}");
    // TODO(eric): Caching is broken in this version, re-enable when fixed.
    // await _audioPlayer.setSource(AssetSource(assetLocation));
  }

  Future playAudioFile(String assetLocation, {bool? loop}) async {
    _logger.log(Level.FINE, "Playing ${assetLocation}");
    await _audioPlayer.play(AssetSource(assetLocation));
    if (loop != null && loop) {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    } else {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    }
  }

  Future stopPlayingAudio() async {
    await _audioPlayer.stop();
  }

  Future clearCache() async {
    await _audioPlayer.audioCache.clearAll();
  }
}