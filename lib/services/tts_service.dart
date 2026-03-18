import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../utils/ui_helpers.dart';
import 'api_service.dart';

/// Robot speaker TTS service.
///
/// Primary path: backend Edge TTS endpoint (`/api/tts/speak`) using
/// Hong Kong Cantonese voice.
/// Fallback path: Google TTS bytes + `/api/audio/play-base64`.
class TTSService {
  static const String _hkVoice = 'zh-HK-HiuGaaiNeural';

  static Future<http.Response> _sendRobotAudio(List<int> mp3Bytes) {
    return http
        .post(
          Uri.parse('${ApiService.baseUrl}/api/audio/play-base64'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'audio_data': base64Encode(mp3Bytes),
            'format': 'mp3',
          }),
        )
        .timeout(const Duration(seconds: 10));
  }

  static Future<bool> _speakWithBackend(String text) async {
    final response = await ApiService.speakTts(text: text, voice: _hkVoice);
    return response.statusCode == 200;
  }

  /// Speaks any text on the robot using Hong Kong Cantonese.
  static Future<void> speak(String text, {BuildContext? context}) async {
    final uiContext = context;
    if (text.trim().isEmpty) return;

    try {
      // Preferred: backend Edge TTS with explicit HK voice.
      final backendOk = await _speakWithBackend(text);
      if (uiContext != null && !uiContext.mounted) return;
      if (backendOk) {
        debugPrint('Robot spoke (Edge TTS, $_hkVoice): $text');
        return;
      }

      // Fallback: Google Translate TTS with Hong Kong Cantonese.
      final uri = Uri.parse(
        'https://translate.google.com/translate_tts'
        '?ie=UTF-8&tl=zh-HK&client=tw-ob&q=${Uri.encodeComponent(text)}',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (uiContext != null && !uiContext.mounted) return;

      if (response.statusCode != 200) {
        _showError('Google TTS failed: ${response.statusCode}', uiContext);
        return;
      }

      final robotResponse = await _sendRobotAudio(response.bodyBytes);
      if (uiContext != null && !uiContext.mounted) return;

      if (robotResponse.statusCode == 200) {
        debugPrint('Robot spoke (fallback zh-HK): $text');
      } else {
        _showError('Robot play failed: ${robotResponse.statusCode}', uiContext);
      }
    } catch (e) {
      if (uiContext != null && !uiContext.mounted) return;
      _showError('Speak error: $e', uiContext);
    }
  }

  static void _showError(String message, BuildContext? context) {
    debugPrint('TTS Error: $message');
    if (context != null && context.mounted) {
      UiHelpers.showError(context, message);
    }
  }
}