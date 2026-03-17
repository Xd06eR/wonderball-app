import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:typed_data';
import '../services/api_service.dart';

/// Live camera screen using snapshot polling.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const String _streamErrorMessage =
      'No video stream\n• Connect to WonderBall WiFi\n• Ensure robot server is running';

  Uint8List? _frameBytes;
  String? _error;
  Timer? _timer;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _fetchFrame();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _fetchFrame());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchFrame() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final snapshotBytes = await ApiService.fetchCameraSnapshot();
      if (!mounted) return;
      setState(() {
        _frameBytes = snapshotBytes;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = _streamErrorMessage);
      }
    } finally {
      _fetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _error != null
              ? Center(child: Text(_error!, textAlign: TextAlign.center))
              : _frameBytes == null
                  ? const Center(child: CircularProgressIndicator())
                  : Transform.rotate(
                      angle: 3 * math.pi,
                      child: Image.memory(
                        _frameBytes!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Live camera'),
        ),
      ],
    );
  }
}