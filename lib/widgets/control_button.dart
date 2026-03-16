import 'package:flutter/material.dart';

/// Reusable circular control button used in MovementScreen.
class ControlButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const ControlButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(24),
          backgroundColor: Colors.blueAccent,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 28, color: Colors.white),
        ),
      ),
    );
  }
}