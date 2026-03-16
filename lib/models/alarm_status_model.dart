/// Data model for cry-detection alarm status.
class AlarmStatus {
  final bool enabled;
  final String state; // 'alarming', 'idle', etc.

  const AlarmStatus({required this.enabled, required this.state});

  factory AlarmStatus.fromJson(Map<String, dynamic> json) {
    return AlarmStatus(
      enabled: json['enabled'] ?? false,
      state: json['state'] ?? 'unknown',
    );
  }
}