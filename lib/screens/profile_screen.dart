import 'package:flutter/material.dart';

/// Simple profile screen showing points and user info.
class ProfileScreen extends StatelessWidget {
  final int points;
  final String userName;

  const ProfileScreen({
    super.key,
    required this.points,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              'User Profile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.blueAccent),
                title: const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(userName, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text('Total Points', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$points 分', style: const TextStyle(fontSize: 36, color: Colors.green)),
                trailing: const Icon(Icons.trending_up, color: Colors.green, size: 40),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Keep answering MCQs to earn more points!\n答啱每題加10分！',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}