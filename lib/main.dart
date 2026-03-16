import 'package:flutter/material.dart';
import 'dart:async';
import 'services/api_service.dart';
import 'screens/movement_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/speaker_screen.dart';
import 'screens/detection_screen.dart';
import 'screens/lesson_screen.dart';
import 'screens/profile_screen.dart';
import 'utils/ui_helpers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WonderBallApp());
}

class WonderBallApp extends StatelessWidget {
  const WonderBallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WonderBall Prototype',
      theme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _totalPoints = 0;
  final String _userName = 'Username';
  bool _isConnected = false;
  Timer? _connectionTimer;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _connectionTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkConnection());
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final connected = await ApiService.checkConnection();
    if (mounted) setState(() => _isConnected = connected);
  }

  void _addPoints(int points) {
    setState(() => _totalPoints += points);
    UiHelpers.showSuccess(context, '好叻！加 $points 分！總分: $_totalPoints');
  }

  List<Widget> get _pages => [
        const MovementScreen(),
        const CameraScreen(),
        const SpeakerScreen(),
        const DetectionScreen(),
        LessonScreen(onAddPoints: _addPoints),
        ProfileScreen(points: _totalPoints, userName: _userName),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WonderBall'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          GestureDetector(
            onTap: _checkConnection,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: _isConnected ? Colors.green : Colors.red)),
                const SizedBox(width: 8),
                Text(_isConnected ? 'Connected' : 'Disconnected'),
                const SizedBox(width: 8),
                const IconButton(icon: Icon(Icons.refresh), onPressed: null),
              ]),
            ),
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'Move'),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), label: 'Camera'),
          BottomNavigationBarItem(icon: Icon(Icons.record_voice_over), label: 'Speak'),
          BottomNavigationBarItem(icon: Icon(Icons.hearing), label: 'Detect'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Lesson'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
    );
  }
}