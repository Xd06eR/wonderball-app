import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/control_button.dart';
import '../utils/ui_helpers.dart';

/// Movement control screen with differential drive for the spherical robot.
class MovementScreen extends StatelessWidget {
  const MovementScreen({super.key});

  Future<void> _runCommand(
    BuildContext context,
    Future<dynamic> Function() action,
    String successMessage,
    String failurePrefix,
  ) async {
    final res = await action();
    if (!context.mounted) return;

    if (res.statusCode == 200) {
      UiHelpers.showSuccess(context, successMessage);
      return;
    }
    UiHelpers.showError(context, '$failurePrefix: ${res.statusCode}');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Movement Control', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ControlButton(label: '▲', onPressed: () => _move(context, 180, 180)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ControlButton(label: '◄', onPressed: () => _move(context, -180, 180)),
                        const SizedBox(width: 60),
                        ControlButton(label: '►', onPressed: () => _move(context, 180, -180)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ControlButton(label: '▼', onPressed: () => _move(context, -180, -180)),
                  ],
                ),
                const Spacer(flex: 1),
              ],
            ),

            const SizedBox(height: 60),

            ElevatedButton.icon(
              icon: const Icon(Icons.stop, color: Colors.white, size: 32),
              label: const Text('STOP', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => _stop(context),
            ),

            const Padding(
              padding: EdgeInsets.all(30),
              child: Text(
                'Differential drive for spherical robot\n'
                '▲ Forward   ▼ Backward\n'
                '◄ Spin Left   ► Spin Right',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _move(BuildContext context, int left, int right) async {
    await _runCommand(
      context,
      () => ApiService.move(leftSpeed: left, rightSpeed: right),
      'Moving → L=$left R=$right',
      'Move failed',
    );
  }

  Future<void> _stop(BuildContext context) async {
    await _runCommand(
      context,
      ApiService.stop,
      '🛑 Robot Stopped',
      'Stop failed',
    );
  }
}