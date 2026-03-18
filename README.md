# WonderBall Parent App (Flutter)

WonderBall is a parent-facing mobile app for a spherical home robot. It supports remote interaction, child monitoring, and STEM learning activities.

This repository contains a school-project prototype built with Flutter.

Backend robotics services are implemented in a separate repository:
- https://github.com/AnaOnTram/Spherical_STEM_Robot

## Academic Prototype Notice

- This is an educational prototype, not a production-ready commercial product.
- The backend repository is maintained by a teammate and integrated here as an external dependency.
- Several workflows are intentionally simplified for coursework demonstrations and testing.

## Project Vision

The project is designed for busy parents who are away from home but still want meaningful interaction with their child during breaks.

Core interaction model:
- A parent connects to WonderBall remotely.
- The child interacts with the robot physically.
- The parent supervises and confirms learning outcomes through the app.

Current prototype lesson workflow:
- Child gestures are used to select lesson options.
- The parent confirms the final answer in the app.
- Correct, parent-confirmed answers award points and trigger a robot spin celebration.
- Quiz voice is configured to Hong Kong Cantonese (Edge TTS).

## Scope of This Repository

This repository contains only the Flutter mobile app.

Backend responsibilities (robot control, detection, event streaming, and LLM/audio pipelines) are implemented in the backend repository above.

## Current App Features

- Robot connection status check (`/api/status`)
- Movement control (`/api/movement/move`, `/api/movement/stop`)
- Camera snapshot preview (`/api/stream/snapshot`)
- Audio playback to robot (`/api/audio/play-base64`, `/api/audio/stop`)
- Server-side TTS playback (`/api/tts/speak`, HK default voice: `zh-HK-HiuGaaiNeural`)
- Alarm monitor controls (`/api/alarm/status`, `enable`, `disable`, `acknowledge`)
- In-app alarm trigger notice for `confirmed` and `alarming` states
- STEM lesson flow including:
  - Lesson image push to e-ink display (`/api/display/update`)
  - Child gesture event intake via WebSocket (`/ws`, `gesture_detected`)
  - Gesture fallback polling (`/api/gesture/status`) for robustness
  - Robust gesture normalization for labels (for example: `victory`, `open palm`, `option_a`) and duplicate-event filtering
  - Backend quiz session lifecycle (`/api/quiz/start`, `/api/quiz/stop`)
  - Lesson dialog shows child-detected option and raw gesture payload for debugging transparency
  - Parent-confirmed answer submission
  - Score update and completion lock after a correct answer
  - Robot spin reward after a correct answer

## App Structure

`lib/`
- `main.dart`: app shell, bottom navigation, global points state
- `screens/`: feature UI screens (`movement`, `camera`, `speaker`, `detection`, `lesson`, `profile`)
- `services/`: API, TTS, audio stream, e-ink conversion, gesture WebSocket
- `models/`: typed data models (for example, alarm status)
- `widgets/`: reusable controls (`ControlButton`, `LessonButton`)
- `utils/`: shared UI helpers (snackbar feedback)

## Backend Integration Notes

Primary API reference:
- https://github.com/AnaOnTram/Spherical_STEM_Robot/blob/main/API.md

Important contract details used by this app:
- REST base URL: `http://<raspberry-pi-ip>:8000`
- WebSocket URL: `ws://<raspberry-pi-ip>:8000/ws`
- Gesture event: `gesture_detected`
- Gesture answer mapping: `1->A`, `2->B`, `3->C`, `4->D`
- Quiz voice options include `zh-HK-HiuGaaiNeural` and `zh-HK-WanLungNeural`
- Alarm states: `idle`, `detecting`, `confirmed`, `alarming`, `cooldown`, `disabled`

## Setup (Flutter App)

1. Install Flutter SDK (stable channel).
2. Clone this repository.
3. Install dependencies:

```bash
flutter pub get
```

4. Set the robot API host in `lib/core/constants.dart`:

```dart
const String piBaseUrl = 'http://<your-robot-ip>:8000';
```

5. Run the app:

```bash
flutter run
```

## Setup (Backend Robot Service)

Follow the backend quick start guide:
- https://github.com/AnaOnTram/Spherical_STEM_Robot#quick-start

Backend ownership note:
- The backend service is developed in a separate teammate-managed repository.

## Dependencies

From `pubspec.yaml`:
- `http`: REST API calls
- `audioplayers`: live audio stream playback
- `image`: image processing for e-ink payload generation
- `web_socket_channel`: real-time gesture event subscription

## Prototype Limitations

- Lesson progress is currently in memory and resets when the app restarts.
- Gesture recognition quality still depends on camera angle, lighting, and hand visibility.
- TTS uses backend Edge TTS first; if unavailable, app falls back to Google TTS + `/api/audio/play-base64`.
- Alarm notifications are currently in-app only (alert sound + dialog), not OS push notifications.

## Acknowledgements

- WonderBall backend contributors:
  https://github.com/AnaOnTram/Spherical_STEM_Robot
- This app repository provides parent mobile control and interaction for the WonderBall ecosystem.
- School project team collaboration made this prototype possible.