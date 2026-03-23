import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../services/audio_stream_service.dart';
import '../services/api_service.dart';
import '../utils/ui_helpers.dart';

/// Speaker & live audio screen.
class SpeakerScreen extends StatefulWidget {
  const SpeakerScreen({super.key});

  @override
  State<SpeakerScreen> createState() => _SpeakerScreenState();
}

class _SpeakerScreenState extends State<SpeakerScreen> {
  bool _isListening = false;
  bool _isSpeaking = false;

  Future<void> _runSafe(Future<void> Function() action, String errorPrefix) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        UiHelpers.showError(context, '$errorPrefix: $e');
      }
    }
  }

  Widget _buildPhraseButton({
    required String label,
    required String phrase,
    required IconData icon,
  }) {
    return ElevatedButton.icon(
      icon: _isSpeaking
          ? const CircularProgressIndicator(color: Colors.white)
          : Icon(icon),
      label: Text(label),
      onPressed: _isSpeaking ? null : () => _speak(phrase),
    );
  }

  Future<void> _startListening() async {
    if (_isListening) return;
    await _runSafe(() async {
      await AudioStreamService.start(ApiService.audioStreamUrl);
      if (mounted) setState(() => _isListening = true);
    }, 'Stream failed');
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    try {
      await AudioStreamService.stop();
      if (mounted) setState(() => _isListening = false);
    } catch (e) {
      if (mounted) UiHelpers.showError(context, 'Stop stream failed: $e');
    }
  }

  Future<void> _speak(String text) async {
    setState(() => _isSpeaking = true);
    await TTSService.speak(text, context: context);
    if (mounted) setState(() => _isSpeaking = false);
  }

  Future<void> _stopAllAudio() async {
    final res = await ApiService.stopAudio();
    if (!mounted) return;

    if (res.statusCode == 200) {
      UiHelpers.showSuccess(context, '🛑 All audio stopped');
    } else {
      UiHelpers.showError(context, 'Stop failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Make WonderBall Speak',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Fixed phrases
            _buildPhraseButton(
              label: '你好！我係WonderBall！好開心見到你。',
              phrase: '你好！我係WonderBall！好開心見到你。',
              icon: Icons.record_voice_over,
            ),
            const SizedBox(height: 12),
            _buildPhraseButton(
              label: '做得好！你好叻呀！繼續努力啦！',
              phrase: '做得好！你好叻呀！繼續努力啦！',
              icon: Icons.child_care,
            ),
            const SizedBox(height: 12),

            // Custom text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: '輸入想講嘅說話 (Enter what WonderBall should say)',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (text) =>
                    text.isNotEmpty && !_isSpeaking ? _speak(text) : null,
              ),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),

            // Live microphone listening
            const Text(
              'Live Audio from Robot',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Listen to robot microphone in real-time',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start (開始)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: _isListening ? null : _startListening,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop (停止)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _isListening ? _stopListening : null,
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text(
              _isListening ? 'Listening to robot microphone...\n正在收聽機械人咪高峰' : 'Press Start to listen to the robot\n按「開始」聽機械人聲音',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.volume_off),
              label: const Text('Stop All Audio (停播所有聲音)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: _stopAllAudio,
            ),
          ],
        ),
      ),
    );
  }
}