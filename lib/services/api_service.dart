import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/alarm_status_model.dart';

/// Central API repository – all robot communication goes through here.
class ApiService {
  static const String baseUrl = piBaseUrl;
  static const Duration _defaultTimeout = Duration(seconds: 8);

  // Shared HTTP helpers keep endpoints concise and consistent.
  static Future<http.Response> _get(
    String path, {
    Duration timeout = _defaultTimeout,
  }) {
    return http.get(Uri.parse('$baseUrl$path')).timeout(timeout);
  }

  static Future<http.Response> _post(
    String path, {
    Duration timeout = _defaultTimeout,
  }) {
    return http.post(Uri.parse('$baseUrl$path')).timeout(timeout);
  }

  static Future<http.Response> _postJson(
    String path,
    Map<String, dynamic> payload, {
    Duration timeout = _defaultTimeout,
  }) {
    return http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        )
        .timeout(timeout);
  }

  /// General health check
  static Future<bool> checkConnection() async {
    try {
      final res = await _get('/api/status', timeout: const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Movement ──
  static Future<http.Response> move({
    required int leftSpeed,
    required int rightSpeed,
    int durationMs = 0,
  }) async =>
      _postJson(
        '/api/movement/move',
        {
          'left_speed': leftSpeed,
          'right_speed': rightSpeed,
          'duration_ms': durationMs,
        },
      );

  static Future<http.Response> stop() async =>
      _post('/api/movement/stop');

  // ── Audio & Display ──
  static String get audioStreamUrl => '$baseUrl/api/stream/audio';

  static Future<http.Response> stopAudio() async =>
      _post('/api/audio/stop');

  static Future<http.Response> speakTts({
    required String text,
    String voice = 'zh-HK-HiuGaaiNeural',
  }) async =>
      _postJson('/api/tts/speak', {'text': text, 'voice': voice});

  static Future<http.Response> updateDisplay(String base64Image) async =>
      _postJson('/api/display/update', {'image_base64': base64Image});

  static Future<Uint8List> fetchCameraSnapshot() async {
    final res = await _get('/api/stream/snapshot', timeout: const Duration(seconds: 5));
    if (res.statusCode != 200) {
      throw Exception('Snapshot fetch failed: ${res.statusCode}');
    }
    return res.bodyBytes;
  }

  // ── STEM quiz & gesture ──
  static Future<http.Response> startQuiz({
    required String question,
    required List<String> options,
    required int correctIndex,
    String title = 'WonderBall STEM',
    String voice = 'zh-HK-HiuGaaiNeural',
    bool shuffle = false,
    double resultDelay = 2.5,
  }) async {
    return _postJson(
      '/api/quiz/start',
      {
        'voice': voice,
        'shuffle': shuffle,
        'result_delay': resultDelay,
        'questions': [
          {
            'question': question,
            'options': options,
            'correct_index': correctIndex,
            'title': title,
          }
        ],
      },
    );
  }

  static Future<Map<String, dynamic>> getQuizStatus() async {
    final res = await _get('/api/quiz/status');
    if (res.statusCode != 200) {
      throw Exception('Quiz status failed: ${res.statusCode}');
    }

    final data = json.decode(res.body);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid quiz status payload');
    }
    return data;
  }

  static Future<http.Response> stopQuiz() async =>
      _post('/api/quiz/stop');

  static Future<Map<String, dynamic>> getGestureStatus() async {
    final res = await _get('/api/gesture/status');
    if (res.statusCode != 200) {
      throw Exception('Gesture status failed: ${res.statusCode}');
    }

    final data = json.decode(res.body);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid gesture status payload');
    }
    return data;
  }

  // ── Alarm (cry / sound detection) ──
  static Future<http.Response> enableAlarm() async =>
      _post('/api/alarm/enable');

  static Future<http.Response> disableAlarm() async =>
      _post('/api/alarm/disable');

  static Future<http.Response> acknowledgeAlarm() async =>
      _post('/api/alarm/acknowledge');

  static Future<AlarmStatus> getAlarmStatus() async {
    final res = await _get('/api/alarm/status');
    if (res.statusCode == 200) {
      return AlarmStatus.fromJson(json.decode(res.body));
    }
    throw Exception('Alarm status failed: ${res.statusCode}');
  }
}