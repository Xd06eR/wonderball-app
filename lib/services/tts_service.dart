import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../utils/ui_helpers.dart';
import 'api_service.dart';

/// Robot speaker TTS service.
/// Primary: backend /api/tts/speak
/// Fallback: Google TTS bytes -> /api/audio/play-base64
class TTSService {
  static const String _hkVoice = 'zh-HK-HiuGaaiNeural';
  static Future<void> _queue = Future<void>.value();

  // Removed async to prevent the closure from capturing context across an async gap
  static Future<void> speak(String text, {BuildContext? context}) {
    _queue = _queue.then((_) => _speakInternal(text));
    return _queue;
  }

  static Future<void> _speakInternal(String text, {BuildContext? context}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    try {
      // 1) Preferred: backend TTS
      final backendRes = await ApiService.speakTts(text: trimmed, voice: _hkVoice);
      if (backendRes.statusCode == 200) {
        debugPrint('Robot spoke (backend TTS): $trimmed');
        return;
      }

      // 2) Fallback: Google TTS (zh-HK) -> robot play-base64
      final googleUri = Uri.parse(
        'https://translate.google.com/translate_tts'
        '?ie=UTF-8&tl=zh-HK&client=tw-ob&q=${Uri.encodeComponent(trimmed)}',
      );
      final googleRes = await http.get(googleUri).timeout(const Duration(seconds: 8));
      if (googleRes.statusCode != 200) {
        if (context != null && context.mounted) {
          UiHelpers.showError(context, 'Google TTS failed: ${googleRes.statusCode}');
        }
        return;
      }

      final robotRes = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/api/audio/play-base64'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'audio_data': base64Encode(googleRes.bodyBytes),
              'format': 'mp3',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (robotRes.statusCode != 200) {
        if (context != null && context.mounted) {
          UiHelpers.showError(context, 'Robot play failed: ${robotRes.statusCode}');
        }
      }
    } catch (e) {
      if (context != null && context.mounted) {
        UiHelpers.showError(context, 'Speak error: $e');
      }
    }
  }
}