import 'package:audioplayers/audioplayers.dart';

/// Simple wrapper for live microphone streaming from the robot.
class AudioStreamService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> start(String streamUrl) async {
    if (_isPlaying) return;
    await _player.play(UrlSource(streamUrl));
    _isPlaying = true;
  }

  static Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  static bool get isPlaying => _isPlaying;
}