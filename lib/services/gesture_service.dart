import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart';

class GestureChoice {
  final int optionIndex;
  final String rawGesture;

  const GestureChoice({required this.optionIndex, required this.rawGesture});

  String get optionLabel => String.fromCharCode(65 + optionIndex);
}

/// Receives gesture events from backend WebSocket and maps them to A/B/C/D options.
class GestureService {
  // Primary quiz path remains finger-count mapping: 1->A, 2->B, 3->C, 4->D.
  static const Map<String, int> _gestureAliasToOption = <String, int>{
    // Canonical labels from backend CV pipeline.
    'pointing_up': 0,
    'peace': 1,
    'open_palm': 3,

    // Common raw/legacy aliases.
    'victory': 1,
    'a': 0,
    'option_a': 0,
    'one': 0,
    'b': 1,
    'option_b': 1,
    'two': 1,
    'c': 2,
    'option_c': 2,
    'three': 2,
    'd': 3,
    'option_d': 3,
    'four': 3,
  };

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pollTimer;
  DateTime? _lastEmissionAt;
  String? _lastGestureTimestamp;
  int? _lastFingerCount;
  final StreamController<GestureChoice> _choicesController = StreamController<GestureChoice>.broadcast();

  Stream<GestureChoice> get choices => _choicesController.stream;

  Future<void> connect() async {
    if (_channel != null) return;

    final wsBase = ApiService.baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
    _channel = WebSocketChannel.connect(Uri.parse('$wsBase/ws'));

    _subscription = _channel!.stream.listen(
      _handleIncoming,
      onError: (error, stackTrace) {
        if (!_choicesController.isClosed) {
          _choicesController.addError(error, stackTrace);
        }
      },
    );

    _channel!.sink.add(jsonEncode({
      'type': 'subscribe',
      'events': ['gesture_detected'],
    }));

    // Fallback/debug channel from REST to keep child-choice updates flowing, even when WebSocket payloads are sparse.
    _startGesturePolling();
  }

  void _startGesturePolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 900), (_) async {
      try {
        final status = await ApiService.getGestureStatus();
        _handleGestureStatus(status);
      } catch (_) {
        // Keep polling silently; WebSocket may still provide events.
      }
    });
  }

  void _handleGestureStatus(Map<String, dynamic> status) {
    if (_choicesController.isClosed) return;

    final payload = _extractGesturePayload(status);

    final handUp = payload['hand_up'];
    if (handUp is bool && !handUp) return;

    final fingerCount = _toInt(payload['finger_count']);
    final optionIndex = _mapFingerCountToOptionIndex(fingerCount);
    final optionFromGesture =
        optionIndex ?? _mapGestureToOptionIndex(payload['gesture']?.toString());
    if (optionFromGesture == null) return;

    final timestamp = payload['timestamp']?.toString();
    final nextFingerCount = fingerCount ?? _toInt(payload['gesture']);
    if (_isDuplicateGesture(timestamp: timestamp, fingerCount: nextFingerCount)) {
      return;
    }

    _rememberGesture(timestamp: timestamp, fingerCount: nextFingerCount);

    _choicesController.add(
      GestureChoice(
        optionIndex: optionFromGesture,
        rawGesture: fingerCount != null
            ? 'finger_count:$fingerCount'
            : payload['gesture']?.toString() ?? 'unknown',
      ),
    );
  }

  void _handleIncoming(dynamic payload) {
    if (payload is! String || _choicesController.isClosed) return;

    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) return;

    final rawType = (decoded['type'] ?? '').toString().toLowerCase();
    if (rawType != 'gesture_detected') return;

    final data = _extractGesturePayload(decoded);

    final handUp = data['hand_up'];
    if (handUp is bool && !handUp) return;

    final fingerCount = _toInt(data['finger_count']);
    final optionFromFingerCount = _mapFingerCountToOptionIndex(fingerCount);
    if (optionFromFingerCount != null) {
      final timestamp = data['timestamp']?.toString() ?? decoded['timestamp']?.toString();
      if (_isDuplicateGesture(timestamp: timestamp, fingerCount: fingerCount)) return;
      _rememberGesture(timestamp: timestamp, fingerCount: fingerCount);

      _choicesController.add(
        GestureChoice(
          optionIndex: optionFromFingerCount,
          rawGesture: 'finger_count:${data['finger_count']}',
        ),
      );
      return;
    }

    final gestureValue = data['gesture'] ?? data['option'] ?? data['label'];
    final optionIndex = _mapGestureToOptionIndex(gestureValue?.toString());
    if (optionIndex == null) return;

    final timestamp = data['timestamp']?.toString() ?? decoded['timestamp']?.toString();
    final numericGesture = _toInt(gestureValue);
    if (_isDuplicateGesture(timestamp: timestamp, fingerCount: numericGesture)) return;
    _rememberGesture(timestamp: timestamp, fingerCount: numericGesture);

    _choicesController.add(
      GestureChoice(
        optionIndex: optionIndex,
        rawGesture: gestureValue.toString(),
      ),
    );
  }

  int? _mapFingerCountToOptionIndex(int? fingerCount) {
    if (fingerCount == null || fingerCount < 1 || fingerCount > 4) return null;
    return fingerCount - 1;
  }

  int? _mapGestureToOptionIndex(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final normalized = _normalizeGesture(raw);

    final numeric = int.tryParse(normalized);
    final optionFromFingerCount = _mapFingerCountToOptionIndex(numeric);
    if (optionFromFingerCount != null) return optionFromFingerCount;

    final compact = normalized.replaceAll('_', '');

    return _gestureAliasToOption[normalized] ?? _gestureAliasToOption[compact];
  }

  String _normalizeGesture(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Map<String, dynamic> _extractGesturePayload(Map<String, dynamic> source) {
    final nested = source['data'];
    if (nested is Map<String, dynamic>) return nested;
    return source;
  }

  bool _isDuplicateGesture({String? timestamp, int? fingerCount}) {
    if (timestamp != null && timestamp == _lastGestureTimestamp && fingerCount == _lastFingerCount) {
      return true;
    }

    if (timestamp == null && fingerCount != null && fingerCount == _lastFingerCount && _lastEmissionAt != null) {
      final elapsed = DateTime.now().difference(_lastEmissionAt!);
      if (elapsed < const Duration(milliseconds: 700)) return true;
    }

    return false;
  }

  void _rememberGesture({String? timestamp, int? fingerCount}) {
    _lastGestureTimestamp = timestamp;
    _lastFingerCount = fingerCount;
    _lastEmissionAt = DateTime.now();
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> dispose() async {
    _pollTimer?.cancel();
    _pollTimer = null;

    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;

    await _choicesController.close();
  }
}
