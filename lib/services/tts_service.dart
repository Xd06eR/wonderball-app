import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../utils/ui_helpers.dart';
import 'api_service.dart';

/// Robot Speaker Service – Pure API-based (Google TTS + robot playback)
/// Uses Hong Kong Cantonese (zh-HK)
class TTSService {
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

  /// Speaks any text on the robot using Hong Kong Cantonese.
  static Future<void> speak(String text, {BuildContext? context}) async {
    final uiContext = context;

    try {
      // Google Translate TTS with Hong Kong Cantonese
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
        debugPrint('Robot spoke (zh-HK): $text');
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