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
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pollTimer;
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

    // Fallback/debug channel from REST to keep child-choice updates flowing
    // even when WebSocket payloads are sparse.
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

    final handUp = status['hand_up'];
    if (handUp is bool && !handUp) return;

    final fingerCount = _toInt(status['finger_count']);
    final optionIndex = _mapFingerCountToOptionIndex(fingerCount);
    if (optionIndex == null) return;

    final timestamp = status['timestamp']?.toString();
    if (timestamp != null && timestamp == _lastGestureTimestamp && fingerCount == _lastFingerCount) {
      return;
    }

    _lastGestureTimestamp = timestamp;
    _lastFingerCount = fingerCount;

    _choicesController.add(
      GestureChoice(
        optionIndex: optionIndex,
        rawGesture: 'finger_count:$fingerCount',
      ),
    );
  }

  void _handleIncoming(dynamic payload) {
    if (payload is! String || _choicesController.isClosed) return;

    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) return;

    final rawType = (decoded['type'] ?? '').toString().toLowerCase();
    if (rawType != 'gesture_detected') return;

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) return;

    final optionFromFingerCount = _mapFingerCountToOptionIndex(_toInt(data['finger_count']));
    if (optionFromFingerCount != null) {
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

    final normalized = raw.trim().toUpperCase().replaceAll(' ', '').replaceAll('-', '_');

    final numeric = int.tryParse(normalized);
    final optionFromFingerCount = _mapFingerCountToOptionIndex(numeric);
    if (optionFromFingerCount != null) return optionFromFingerCount;

    const mapping = <String, int>{
      'A': 0,
      'OPTION_A': 0,
      'ONE': 0,
      '1': 0,
      'B': 1,
      'OPTION_B': 1,
      'TWO': 1,
      '2': 1,
      'VICTORY': 1,
      'PEACE': 1,
      'C': 2,
      'OPTION_C': 2,
      'THREE': 2,
      '3': 2,
      'D': 3,
      'OPTION_D': 3,
      'FOUR': 3,
      '4': 3,
    };

    return mapping[normalized];
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
