<div align="center">
  <img src="assets/images/icon.png" alt="GymOS icon" width="120" />

  # GymOS

  **Offline-first workout, nutrition and progress tracking built with Flutter.**

  Plan workouts, log sets and meals, scan nutrition labels and keep an optional
  private cloud backup through Firebase.
</div>

> [!IMPORTANT]
> GymOS provides fitness and nutrition calculations for informational purposes
> only. It is not a medical device and does not replace advice from a qualified
> healthcare, nutrition or exercise professional.

## Features

### Workouts

- Create multi-day workout plans.
- Start from built-in training templates.
- Log weight and repetitions set by set.
- Keep the rest timer running while navigating between exercises.
- Review recent sets and workout history.
- Track load progression for each exercise.
- Estimate one-repetition maximum values.

### Nutrition

- Track calories, protein, carbohydrates and fat.
- Organize food entries into configurable meals.
- Search the OpenFoodFacts food database.
- Scan product barcodes.
- Read nutrition labels with on-device OCR.
- Create and edit custom foods.
- Copy and reorder meal entries.
- Generate nutrition reports as PDF files.

### Progress and tools

- Record body-weight history.
- Calculate calorie and macro targets.
- Use batch, cereal and real-weight calculators.
- View progress charts and historical data.
- Use light, dark or AMOLED themes.
- Available in Portuguese, English and Spanish.

### Data

- Local-first storage with Isar.
- Manual backup and restore.
- Optional Google Sign-In.
- Optional Firestore backup and granular cloud synchronization.

## Technology

| Area | Technology |
|---|---|
| Application | Flutter and Dart |
| State management | Riverpod |
| Local database | Isar |
| Authentication | Firebase Auth and Google Sign-In |
| Cloud storage | Cloud Firestore |
| Barcode scanning | Mobile Scanner and Google ML Kit |
| Label recognition | Google ML Kit Text Recognition |
| Food database | OpenFoodFacts API |
| Charts | `fl_chart` |
| Documents | `pdf` and `printing` |

## Supported platforms

| Platform | Status | Notes |
|---|---:|---|
| Android | Primary | Full camera, barcode, OCR and Firebase workflow |
| iOS | Partial | Core Flutter target; requires separate Firebase configuration and device testing |
| Web | Not supported | Current local database and scanning stack are mobile-focused |
| Windows, macOS, Linux | Not supported | Scaffolding exists, but these targets are not production-hardened |

## Requirements

- Flutter SDK compatible with Dart `>=3.0.0 <4.0.0`
- Android Studio and an Android SDK for Android development
- Xcode and CocoaPods for iOS development
- A Firebase project for authentication and cloud backup
- FlutterFire CLI for generating local Firebase configuration
- Firebase CLI for deploying Firestore security rules

Check your toolchain with:

```bash
flutter doctor
```

## Getting started

### 1. Clone and install dependencies

```bash
git clone https://github.com/henrique-correia-it/gym_os.git
cd gym_os
flutter pub get
flutter gen-l10n
```

### 2. Create your Firebase configuration

Create a Firebase project and configure your own Android and/or iOS apps. Real
Firebase configuration files are intentionally excluded from this repository.

Recommended setup:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates local files such as:

```text
lib/firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

These files are ignored by Git. Never commit service-account JSON files,
private keys or administrative credentials.

Templates are provided at:

```text
lib/firebase_options.dart.example
android/app/google-services.json.example
```

### 3. Enable Firebase services

In the Firebase Console:

1. Enable Google in **Authentication → Sign-in method**.
2. Create a Firestore database in production mode.
3. Configure the Android SHA fingerprints required by Google Sign-In.
4. Review authentication quotas and abuse protection.

### 4. Deploy Firestore security rules

The versioned rules in [`firestore.rules`](firestore.rules) isolate every
user's data below `users/{uid}` and deny access to the rest of the database.

Select your Firebase project locally, then deploy only the rules:

```bash
firebase use YOUR_PROJECT_ID
firebase deploy --only firestore:rules
```

Always test with two separate accounts and confirm that neither account can
read or modify the other's documents.

### 5. Run the application

```bash
flutter run
```

The application stores its working data locally. Firebase is used for login and
optional cloud synchronization when configured.

## Building Android

Generate an APK for direct installation:

```bash
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

The current project is intended for direct development/testing distribution.
Before long-term distribution, configure a stable application ID and a private
release-signing key. Never commit the keystore or `key.properties`.

## Quality checks

Run before committing changes:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

The automated suite covers core calorie, BMI, one-repetition-maximum and rest
timer calculations. Database migrations, backup/restore and cloud
synchronization still require integration coverage before production use.

## Project structure

```text
lib/
├── data/
│   ├── database.dart        Isar initialization, import and local backup
│   └── models/              Nutrition, workout and user collections
├── l10n/                    ARB translations and generated localization code
├── providers/               Riverpod application state
├── screens/
│   ├── tools/               Fitness and nutrition calculators
│   └── workout/             Plans, editor, active workout and history
├── services/                Auth, Firestore sync, food API and label scanning
├── utils/                   Theme, calculations and shared helpers
└── widgets/                 Reusable dashboard components

assets/data/                 Exercise and food seed data
firestore.rules              Versioned per-user cloud access rules
```

## Data and security model

GymOS is designed as an offline-first application:

1. The application reads and writes its working data in Isar.
2. A signed-in user may opt into Firestore backup/synchronization.
3. Cloud documents are stored below `users/{firebase_uid}`.
4. Firestore rules restrict access to the matching authenticated user.

Firebase client configuration contains public application identifiers, not
administrative secrets. Security depends on deployed Firestore rules and
correct Firebase Authentication configuration.

Never include any of the following in the application or repository:

- Firebase service-account private keys
- Google Cloud private keys
- Keystores or certificate passwords
- Real exported backups
- Screenshots, fixtures or logs containing personal data

## Privacy

GymOS can process sensitive personal information, including:

- Name and date of birth
- Gender, height and body weight
- Weight history
- Food intake and nutrition targets
- Exercise history, repetitions and training loads

Exported JSON/PDF files may contain this information in readable form. Store
and share them carefully.

Anyone deploying GymOS for other users is responsible for providing an
appropriate privacy policy, deletion process, retention policy and lawful data
handling for their jurisdiction.

Do not use public repository issues to share personal, account, nutrition or
health information.

## Known limitations

- Calorie, macro, BMI and strength calculations are estimates.
- OpenFoodFacts entries are community-maintained and may be incomplete.
- OCR results depend on image quality and must be reviewed before saving.
- Firestore synchronization is not a substitute for a verified backup policy.
- Local Isar data and exported backups are not additionally encrypted by GymOS.
- Camera and scanning behavior varies by device.
- Cloud synchronization and backup/restore do not yet have integration tests.

## Contributing

Contributions are welcome. Keep changes focused, explain user-facing behavior
and include tests when the test infrastructure becomes available.

Suggested workflow:

1. Create a feature branch.
2. Implement and manually verify the change.
3. Run formatting and static analysis.
4. Open a pull request with a clear description and verification steps.

## License

GymOS is available under the [MIT License](LICENSE). You may use, copy, modify,
distribute and sell the software, provided that the copyright and license
notice are retained.
