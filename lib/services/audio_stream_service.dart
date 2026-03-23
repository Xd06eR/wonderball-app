import 'package:just_audio/just_audio.dart';

/// Live microphone streaming wrapper.
class AudioStreamService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> start(String streamUrl) async {
    if (_isPlaying) return;

    // Prepare stream URL first.
    await _player.setUrl(streamUrl);

    // For live stream, just play (no seek/position assumptions).
    await _player.play();
    _isPlaying = true;
  }

  static Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  static bool get isPlaying => _isPlaying;

  static Future<void> dispose() async {
    await _player.dispose();
  }
}