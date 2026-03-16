import 'package:flutter/material.dart';

/// Reusable lesson starter button used in LessonScreen.
class LessonButton extends StatelessWidget {
  final String title;
  final VoidCallback? onStart;
  final bool isCompleted;

  const LessonButton({
    super.key,
    required this.title,
    required this.onStart,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: ElevatedButton.icon(
        icon: Icon(isCompleted ? Icons.lock : Icons.play_arrow),
        label: Text(isCompleted ? '已完成' : '開始'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted ? Colors.grey : Colors.blueAccent,
        ),
        onPressed: onStart,
      ),
    );
  }
}