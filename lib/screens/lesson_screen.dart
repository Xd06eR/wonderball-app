import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/eink_service.dart';
import '../services/gesture_service.dart';
import '../services/tts_service.dart';
import '../widgets/lesson_button.dart';
import '../utils/ui_helpers.dart';

class _LessonItem {
  final String title;
  final String introTts;
  final String lessonText;
  final String imageAssetPath;
  final String question;
  final List<String> options;
  final int correctIndex;

  const _LessonItem({
    required this.title,
    required this.introTts,
    required this.lessonText,
    required this.imageAssetPath,
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class _LessonCategory {
  final IconData icon;
  final Color color;
  final String title;
  final List<_LessonItem> lessons;

  const _LessonCategory({
    required this.icon,
    required this.color,
    required this.title,
    required this.lessons,
  });
}

/// STEM Lessons screen (question first, then image near end of question TTS)
class LessonScreen extends StatefulWidget {
  static const String _defaultIntroTts = '請專心聽書！要開始啦！';

  final void Function(int) onAddPoints;

  const LessonScreen({super.key, required this.onAddPoints});

  @override
  State<LessonScreen> createState() => _LessonScreenState();

  static const List<_LessonCategory> _categories = [
    _LessonCategory(
      icon: Icons.science,
      color: Colors.green,
      title: 'Science 科學',
      lessons: [
        _LessonItem(
          title: 'Lesson 1: Plants 植物需要水',
          introTts: _defaultIntroTts,
          lessonText: '植物好可愛呀！佢哋要飲水先可以長大同開花，無水就會枯㗎啦，記住幫植物淋水哦！',
          imageAssetPath: 'assets/images/lesson_science_plants.png',
          question: '植物長大需要乜嘢呀？',
          options: ['A. 玩具 → 🧸', 'B. 水 → 💧', 'C. 鞋 → 👟', 'D. 水果 → 🍎'],
          correctIndex: 1,
        ),
        _LessonItem(
          title: 'Lesson 2: Fish 魚魚住水',
          introTts: _defaultIntroTts,
          lessonText: '魚魚好開心呀！佢哋住喺水入面，游嚟游去，尾巴擺嚟擺去好可愛！',
          imageAssetPath: 'assets/images/lesson_science_fish.png',
          question: '邊個動物住喺水入面呀？',
          options: ['A. 雀仔 → 🐦', 'B. 狗狗 → 🐶', 'C. 魚魚 → 🐟', 'D. 貓貓 → 🐱'],
          correctIndex: 2,
        ),
      ],
    ),
    _LessonCategory(
      icon: Icons.computer,
      color: Colors.blue,
      title: 'Technology 科技',
      lessons: [
        _LessonItem(
          title: 'Lesson 1: Clock 鐘鐘睇時間',
          introTts: _defaultIntroTts,
          lessonText: '鐘鐘滴答滴答，話我哋知幾多點呀！朝早起床、食飯、挽都要睇鐘㗎！',
          imageAssetPath: 'assets/images/lesson_technology_clock.png',
          question: '邊個用嚟睇時間呀？',
          options: ['A. 尺 → 📏', 'B. 秤 → ⚖️', 'C. 鐘 → 🕰️', 'D. 匙羹 → 🥄'],
          correctIndex: 2,
        ),
        _LessonItem(
          title: 'Lesson 2: Ruler 尺量長度',
          introTts: _defaultIntroTts,
          lessonText: '尺好有用㗎！可以用嚟量枱有幾長、書有幾闊，好似偵探咁周圍度嘢！',
          imageAssetPath: 'assets/images/lesson_technology_ruler.png',
          question: '量枱有多長，用邊個工具最好呀？',
          options: ['A. 溫度計 → 🌡️', 'B. 尺 → 📏', 'C. 鐘 → 🕰️', 'D. 秤 → ⚖️'],
          correctIndex: 1,
        ),
      ],
    ),
    _LessonCategory(
      icon: Icons.engineering,
      color: Colors.orange,
      title: 'Engineering 工程',
      lessons: [
        _LessonItem(
          title: 'Lesson 1: Ice 冰熔化',
          introTts: _defaultIntroTts,
          lessonText: '冰冰好凍呀！但熱咗就會慢慢變成水，流嚟流去，喺咪好神奇呢！',
          imageAssetPath: 'assets/images/lesson_engineering_ice.png',
          question: '冰熔化會變成乜呀？',
          options: ['A. 消失 → 💨', 'B. 水 → 💧', 'C. 煙 → 🌫️', 'D. 沙 → 🏜️'],
          correctIndex: 1,
        ),
        _LessonItem(
          title: 'Lesson 2: Gravity 重力',
          introTts: _defaultIntroTts,
          lessonText: '重力好勁呀！佢會拉啲嘢落地下，好似蘋果喺樹上跌落嚟咁，唔使驚，係正常㗎！',
          imageAssetPath: 'assets/images/lesson_engineering_gravity.png',
          question: '邊個拉東西落地下呀？',
          options: ['A. 光 → 💡', 'B. 聲 → 🔊', 'C. 重力 → ⬇️', 'D. 風 → 🌬️'],
          correctIndex: 2,
        ),
      ],
    ),
    _LessonCategory(
      icon: Icons.calculate,
      color: Colors.purple,
      title: 'Math 數學',
      lessons: [
        _LessonItem(
          title: 'Lesson 1: Triangle 三角形',
          introTts: _defaultIntroTts,
          lessonText: '三角形有三條邊同三個角！好似pizza或者屋頂咁，都係三角形嚟㗎！',
          imageAssetPath: 'assets/images/lesson_math_triangle.png',
          question: '三角形有幾多條邊呀？',
          options: ['A. 4條 → 4️⃣', 'B. 3條 → 3️⃣', 'C. 5條 → 5️⃣', 'D. 6條 → 6️⃣'],
          correctIndex: 1,
        ),
        _LessonItem(
          title: 'Lesson 2: Ball 波嘅形狀',
          introTts: _defaultIntroTts,
          lessonText: '波係圓形嘅，好似圓圈咁！輪嚟輪去好好玩呀，太陽同月亮都係圓形㗎！',
          imageAssetPath: 'assets/images/lesson_math_ball.png',
          question: '波嘅形狀係邊個呀？',
          options: ['A. 方形 → ■', 'B. 三角形 → 🔺', 'C. 圓形 → ⚪', 'D. 長方形 → ▭'],
          correctIndex: 2,
        ),
      ],
    ),
  ];
}

class _LessonScreenState extends State<LessonScreen> {
  static const Duration _autoCloseDelay = Duration(seconds: 3);
  final Set<String> _completedLessons = <String>{};

  bool _isCompleted(_LessonItem lesson) => _completedLessons.contains(lesson.title);

  void _markCompleted(_LessonItem lesson) {
    setState(() => _completedLessons.add(lesson.title));
  }

  Duration _estimateTtsDuration(String text) {
    final chars = text.runes.length;
    final ms = (chars * 170).clamp(1200, 18000);
    return Duration(milliseconds: ms);
  }

  Future<void> _spinRobotCelebration() async {
    try {
      final res = await ApiService.move(
        leftSpeed: 180,
        rightSpeed: -180,
        durationMs: 3000,
      );
      if (!mounted) return;
      if (res.statusCode != 200) {
        UiHelpers.showError(context, 'Robot spin failed: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) UiHelpers.showError(context, 'Robot spin error: $e');
    }
  }

  Future<void> _startBackendQuizSession(BuildContext context, _LessonItem lesson) async {
    try {
      final response = await ApiService.startQuiz(
        question: lesson.question,
        options: lesson.options,
        correctIndex: lesson.correctIndex,
        title: lesson.title,
      );

      if (!context.mounted) return;
      if (response.statusCode != 200) {
        UiHelpers.showError(context, 'Quiz start failed: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) UiHelpers.showError(context, 'Quiz start error: $e');
    }
  }

  Future<void> _stopBackendQuizSession() async {
    try {
      await ApiService.stopQuiz();
    } catch (_) {
      // best effort
    }
  }

  Future<void> _updateEInkDisplay(BuildContext context, String imageAssetPath) async {
    try {
      final base64Image = await EinkService.convertAssetToBase64(imageAssetPath);
      final response = await ApiService.updateDisplay(base64Image);
      if (!context.mounted) return;

      if (response.statusCode == 200) {
        UiHelpers.showSuccess(context, '✅ E-ink updated');
      } else {
        UiHelpers.showError(context, 'E-ink failed: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) UiHelpers.showError(context, '⚠️ E-ink error: $e');
    }
  }

  Future<void> _speakLessonFlowAndSwapImage({
    required BuildContext context,
    required _LessonItem lesson,
  }) async {
    final questionPrompt = '${lesson.question} 請選擇正確答案！';

    final qDuration = _estimateTtsDuration(questionPrompt);
    const swapLead = Duration(milliseconds: 900);
    final delayBeforeSwap =
        qDuration > swapLead ? qDuration - swapLead : const Duration(milliseconds: 200);

    await TTSService.speak(lesson.introTts, context: context);
    if (!context.mounted) return;
    await TTSService.speak(lesson.lessonText, context: context);
    if (!context.mounted) return;

    final speakFuture = TTSService.speak(questionPrompt, context: context);

    unawaited(() async {
      await Future.delayed(delayBeforeSwap);
      if (!context.mounted) return;
      await _updateEInkDisplay(context, lesson.imageAssetPath);
    }());

    await speakFuture;
  }

  void _startLesson({required BuildContext context, required _LessonItem lesson}) {
    if (_isCompleted(lesson)) return;

    final gestureService = GestureService();
    StreamSubscription<GestureChoice>? gestureSubscription;

    int? selectedIndex;
    int? childSelectedIndex;
    String? childRawGesture;
    String feedback = '';
    String childMessage = 'Waiting for child gesture...';
    bool answered = false;
    bool gestureStarted = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setState) {
            if (!gestureStarted) {
              gestureStarted = true;

              unawaited(() async {
                try {
                  await _startBackendQuizSession(ctx, lesson);
                  await gestureService.connect();

                  gestureSubscription = gestureService.choices.listen((choice) {
                    if (!ctx.mounted || answered) return;
                    if (choice.optionIndex >= lesson.options.length) return;

                    if (childSelectedIndex != choice.optionIndex) {
                      setState(() {
                        childSelectedIndex = choice.optionIndex;
                        childRawGesture = choice.rawGesture;
                        childMessage = 'Child gesture detected: option ${choice.optionLabel}.';
                        selectedIndex ??= choice.optionIndex;
                      });
                      UiHelpers.showSuccess(context, childMessage);
                    }
                  });

                  // Start speaking flow: question on e-ink first (backend quiz), then image near end of question speech.
                  if (!ctx.mounted) return;
                  unawaited(_speakLessonFlowAndSwapImage(context: ctx, lesson: lesson));
                } catch (e) {
                  if (ctx.mounted) {
                    setState(() => childMessage = 'Gesture stream unavailable: $e');
                  }
                }
              }());
            }

            void submitAnswer() {
              if (selectedIndex == null) return;
              final isCorrect = selectedIndex == lesson.correctIndex;

              setState(() {
                answered = true;
                if (isCorrect) {
                  feedback = '啱啦！好叻！加10分！';
                  unawaited(TTSService.speak(feedback, context: context));
                  widget.onAddPoints(10);
                } else {
                  feedback = '唔啱！正確答案係 ${lesson.options[lesson.correctIndex]}';
                  unawaited(TTSService.speak(feedback, context: context));
                }
              });

              if (isCorrect) {
                _markCompleted(lesson);
                unawaited(_spinRobotCelebration());
              }

              Future.delayed(_autoCloseDelay, () {
                if (!ctx.mounted) return;
                if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
              });
            }

            return AlertDialog(
              title: const Text('STEM Lesson', textAlign: TextAlign.center),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        lesson.imageAssetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Text('Image load failed'),
                      ),
                      const SizedBox(height: 20),
                      Text(lesson.lessonText, style: const TextStyle(fontSize: 16, height: 1.5)),
                      const Divider(height: 40, thickness: 2),
                      Text(lesson.question, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text(
                        childMessage,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (childSelectedIndex != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            children: [
                              Text(
                                'Child selected: ${lesson.options[childSelectedIndex!]}',
                                style: const TextStyle(fontSize: 14, color: Colors.lightBlueAccent),
                                textAlign: TextAlign.center,
                              ),
                              if (childRawGesture != null)
                                Text(
                                  'Raw gesture: $childRawGesture',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                      RadioGroup<int>(
                        groupValue: selectedIndex,
                        onChanged: (value) {
                          if (answered) return;
                          setState(() => selectedIndex = value);
                        },
                        child: Column(
                          children: lesson.options.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final opt = entry.value;
                            return RadioListTile<int>(
                              title: Text(opt, style: const TextStyle(fontSize: 18)),
                              value: idx,
                              activeColor: Colors.blueAccent,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: const Text('提交答案', style: TextStyle(fontSize: 20)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedIndex == null ? Colors.grey : Colors.green,
                        ),
                        onPressed: (selectedIndex == null || answered) ? null : submitAnswer,
                      ),
                      const SizedBox(height: 20),
                      if (feedback.isNotEmpty)
                        Text(
                          feedback,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: selectedIndex == lesson.correctIndex ? Colors.green : Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('關閉', style: TextStyle(color: Colors.blueAccent)),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() async {
      await gestureSubscription?.cancel();
      await gestureService.dispose();
      await _stopBackendQuizSession();
    });
  }

  Widget _buildCategoryTile(BuildContext context, _LessonCategory category) {
    return ExpansionTile(
      leading: Icon(category.icon, color: category.color),
      title: Text(category.title, style: const TextStyle(fontSize: 20)),
      children: category.lessons.map((lesson) {
        final completed = _isCompleted(lesson);
        return LessonButton(
          title: lesson.title,
          isCompleted: completed,
          onStart: completed ? null : () => _startLesson(context: context, lesson: lesson),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STEM Lessons', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('選擇課程，按「開始」答問題！答啱加10分，課程會鎖定。', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 24),
          ...LessonScreen._categories.map((category) => _buildCategoryTile(context, category)),
        ],
      ),
    );
  }
}