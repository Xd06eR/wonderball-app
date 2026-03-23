import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../models/alarm_status_model.dart';
import '../utils/ui_helpers.dart';

/// Cry / Sound Detection screen.
class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  AlarmStatus? _alarmStatus;
  bool _isLoading = false;
  Timer? _statusTimer;
  String? _lastState;
  bool _isDialogOpen = false;

  bool _isAlarmState(String state) => state == 'confirmed' || state == 'alarming';

  Future<void> _notifyAlarmTriggered(String state) async {
    if (!mounted || _isDialogOpen) return;

    _isDialogOpen = true;

    // System alert sound (Android-safe).
    await SystemSound.play(SystemSoundType.alert);
    if (!mounted) {
      _isDialogOpen = false;
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cry/Sound Detected'),
          content: Text('WonderBall alarm state: $state'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    _isDialogOpen = false;
  }

  Future<void> _runAlarmAction({
    required Future<dynamic> Function() action,
    required String successMessage,
    bool withLoading = true,
  }) async {
    if (withLoading) {
      setState(() => _isLoading = true);
    }

    try {
      await action();
      if (!mounted) return;
      await _fetchAlarmStatus();
      if (!mounted) return;
      UiHelpers.showSuccess(context, successMessage);
    } catch (e) {
      if (mounted) {
        UiHelpers.showError(context, 'Action failed: $e');
      }
    } finally {
      if (mounted && withLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAlarmStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchAlarmStatus());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAlarmStatus() async {
    try {
      final status = await ApiService.getAlarmStatus();
      if (!mounted) return;

      final previousState = _lastState;
      final nextState = status.state;
      final stateChanged = previousState != nextState;
      final shouldNotify = stateChanged && _isAlarmState(nextState);

      setState(() {
        _alarmStatus = status;
        _lastState = nextState;
      });

      if (shouldNotify) {
        await _notifyAlarmTriggered(nextState);
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showError(context, 'Status fetch failed: $e');
      }
    }
  }

  Future<void> _enableAlarm() async {
    await _runAlarmAction(
      action: ApiService.enableAlarm,
      successMessage: '✅ Cry detection enabled',
    );
  }

  Future<void> _disableAlarm() async {
    await _runAlarmAction(
      action: ApiService.disableAlarm,
      successMessage: '❌ Cry detection disabled',
    );
  }

  Future<void> _acknowledgeAlarm() async {
    await _runAlarmAction(
      action: ApiService.acknowledgeAlarm,
      successMessage: '✅ Alarm acknowledged',
      withLoading: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _alarmStatus?.enabled ?? false;
    final state = _alarmStatus?.state ?? 'unknown';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hearing, size: 120, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text('Cry / Sound Detection', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Alarm Status: ${enabled ? "ENABLED" : "DISABLED"}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'State: $state',
                      style: TextStyle(
                        fontSize: 16,
                        color: _isAlarmState(state) ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.play_circle_fill),
                  label: const Text('Enable Alarm'),
                  onPressed: _isLoading ? null : _enableAlarm,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop_circle),
                  label: const Text('Disable Alarm'),
                  onPressed: _isLoading ? null : _disableAlarm,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Acknowledge'),
                  onPressed: _acknowledgeAlarm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}