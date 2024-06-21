import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:soundpool/soundpool.dart';

/// Manage the single audio player for the application and the sound files cache
/// for low latency playback which is important when running protocols.
class AudioManager {
  final CustomLogPrinter _logger = CustomLogPrinter('AudioManager');

  final Soundpool pool = Soundpool.fromOptions(options: SoundpoolOptions());
  int _lastStreamId = -1;

  AudioManager();

  Future<int> cacheAudioFile(String assetLocation) async {
    _logger.log(Level.FINE, "Caching $assetLocation");
    ByteData soundData = await rootBundle.load(assetLocation);
    return pool.load(soundData);
  }

  Future<int> playAudioFile(int cachedAudioFileId, {int repeat = 0}) async {
    _logger.log(Level.FINE, "Playing cached audio file id $cachedAudioFileId");
    _lastStreamId = await pool.play(cachedAudioFileId, repeat: repeat);
    return _lastStreamId;
  }

  Future stopPlayingAudio(int streamId) async {
    if (streamId >= 0) {
      _logger.log(Level.FINE, "Stopping last audio stream $_lastStreamId");
      await pool.stop(streamId);
    }
  }

  Future stopPlayingLastAudio() async {
    stopPlayingAudio(_lastStreamId);
  }

  Future clearCache() async {
    await pool.release();
  }
}