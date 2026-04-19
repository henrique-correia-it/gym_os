<p align="center">
  <img src="assets/images/icon.png" width="96" alt="GymOS icon" />
</p>

<h1 align="center">GymOS</h1>

<p align="center">
  Open-source fitness &amp; nutrition tracker built with Flutter
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" />
  <img src="https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/License-MIT-green" />
</p>

---

## What is GymOS?

GymOS is an offline-first fitness and nutrition tracking app. Log your meals by scanning barcodes or reading labels with the camera, plan your workouts, and track your progress — all synced to the cloud when you want.

### Features

**Nutrition**
- Barcode scanner (OpenFoodFacts database)
- OCR label scanner — point the camera at any nutrition label
- Custom food creation with full macro tracking
- Daily logs with drag-and-drop meal reordering
- Macro targets and caloric adjustment goals
- PDF report generation

**Workouts**
- Create custom workout plans with multiple training days
- Pre-built workout templates (PPL, Upper/Lower, Full Body, …)
- Active workout session tracking with set-by-set logging
- Load tracker — track your progression per exercise over time

**General**
- Google Sign-In with Firebase Auth
- Cloud backup and restore (Firestore) with debounced sync
- Offline-first — everything works without internet (Isar local DB)
- Dark / Light / AMOLED themes
- Languages: Portuguese 🇵🇹, English 🇬🇧, Spanish 🇪🇸
- Progress charts

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3 |
| State management | Riverpod |
| Local database | Isar |
| Cloud sync | Firebase Firestore |
| Authentication | Firebase Auth (Google Sign-In) |
| ML / Vision | Google ML Kit (barcode + OCR) |
| Food database | OpenFoodFacts API (no key needed) |
| Charts | fl_chart |
| PDF | pdf + printing |

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- A Firebase project — [console.firebase.google.com](https://console.firebase.google.com)
- Android Studio or Xcode for device targets

### 1. Clone

```bash
git clone https://github.com/YOUR_USERNAME/gym_os.git
cd gym_os
```

### 2. Set up Firebase

The Firebase config files are excluded from the repository for security. You need to add your own.

**Option A — FlutterFire CLI (recommended)**

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart` and `android/app/google-services.json` automatically.

**Option B — Manual**

1. Create a new project in the [Firebase Console](https://console.firebase.google.com).
2. Add Android and/or iOS apps to it.
3. Download `google-services.json` → place at `android/app/google-services.json`
4. Download `GoogleService-Info.plist` → place at `ios/Runner/GoogleService-Info.plist`
5. Copy the Firebase options template and fill in your values:

```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
# Edit lib/firebase_options.dart with your project credentials
```

### 3. Enable Firebase services

In the Firebase Console enable:
- **Authentication** → Sign-in method → Google
- **Firestore Database** → Start in production mode

Recommended Firestore security rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 4. Install and run

```bash
flutter pub get
flutter run
```

---

## Project Structure

```
lib/
├── data/
│   ├── database.dart          # Isar setup & migrations
│   └── models/                # Isar schemas (nutrition, workout, user)
├── providers/                 # Riverpod providers
├── screens/                   # UI screens
│   ├── dashboard_screen.dart
│   ├── workout/
│   ├── planner_screen.dart
│   ├── profile_screen.dart
│   └── settings_screen.dart
├── services/
│   ├── auth_service.dart
│   ├── cloud_sync_service.dart
│   ├── food_api_service.dart  # OpenFoodFacts
│   └── label_scanner_service.dart
├── widgets/                   # Reusable widgets
├── utils/
└── l10n/                      # ARB translation files (pt, en, es)
```

---

## Contributing

Contributions are welcome! Please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes following [Conventional Commits](https://www.conventionalcommits.org/)
4. Push and open a Pull Request

---

## License

MIT © [Your Name](https://github.com/YOUR_USERNAME)
