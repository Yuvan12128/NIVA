# NIVA — Universal Need-to-Solution Discovery Platform

NIVA is a modern, intent-driven mobile application built with Flutter that bridges the gap between active needs and capable helpers. By eliminating social media vanity metrics, NIVA prioritizes direct utility through a dual-facet exchange: **"I Need"** and **"I Can Help"**.

---

## Key Features

* **Dual-Facet Publication**: Seamlessly publish requests for help or post capabilities offered to the community.
* **Algorithmic Matching Engine**: Instant 5-factor compatibility scoring (skills, location, urgency, category, and trust).
* **Universal Explore & Search**: Debounced search (300ms) with keyword suggestion chips and trending topics.
* **Consent-Driven 1-to-1 Chat**: Private messaging unlocked only after an explicit connection request is mutually accepted.
* **Verified Community Trust**: 1–5 star post-collaboration reviews and protected Trust Scores.
* **Trust & Safety Suite**: Write-only user reporting, mutual blocking, and strict moderation enforcement.
* **Responsive & Optimized**: Verified zero-overflow compatibility across 8 standard device sizes from 320px entry-level phones to 10" tablets.

---

## Tech Stack & Architecture

* **Framework**: Flutter 3.47.4 (Channel stable)
* **Language**: Dart 3.13.3
* **Backend Platform**: Google Cloud Firestore & Firebase Authentication
* **Architecture**: Modular Feature-Driven Architecture (Presentation, Repository/Service, Data Layer)
* **Package ID**: `com.niva.app`

---

## Firebase Configuration

* **Project ID**: `niva-discovery-1792429167`
* **Configuration Files**:
  * Android: `android/app/google-services.json`
  * FlutterFire Options: `lib/firebase_options.dart`
  * CLI Configuration: `firebase.json`
  * Security Rules: `firestore.rules`

---

## Getting Started

### Prerequisites
* Flutter SDK (3.47.4+)
* Dart SDK (3.13.3+)
* Android SDK / Android Studio (with JDK 17)

### Installation
```bash
# Clone the repository
git clone https://github.com/Yuvan12128/niva.git
cd niva

# Install dependencies
flutter pub get
```

---

## Run Instructions

### 1. Auto-Detect / Interactive Device Selection
```bash
flutter run
```

### 2. Run on Android Emulator
```bash
# Launch installed emulator
flutter emulators --launch Pixel_10_Pro

# Run app on emulator
flutter run -d android
```

### 3. Run on Physical Android Phone
1. Connect device via USB with **Developer Options & USB Debugging** enabled.
2. Confirm device detection:
   ```bash
   flutter devices
   ```
3. Run:
   ```bash
   flutter run -d android
   ```

### 4. Run on Chrome (Web)
```bash
flutter run -d chrome
```

### 5. Run on Linux Desktop
```bash
flutter run -d linux
```

---

## Build Instructions

### Build Android APK (Release)
```bash
flutter build apk --release
```
*Output: `build/app/outputs/flutter-apk/app-release.apk`*

### Build Android App Bundle (AAB for Play Store)
```bash
flutter build appbundle --release
```
*Output: `build/app/outputs/bundle/release/app-release.aab`*

---

## Testing & Quality Assurance

```bash
# Run static analysis (0 warnings / errors)
flutter analyze

# Run full automated test suite (190 passed)
flutter test

# Run responsive device compatibility tests (8 screen sizes)
flutter test test/device_compatibility_test.dart

# Run security hardening unit tests
flutter test test/security_hardening_test.dart
```

---

## Project Documentation & Screenshots

Full documentation is organized in the [`docs/`](docs/) directory:

* 📖 **[Master Comprehensive Documentation](docs/NIVA_COMPLETE_DOCUMENTATION.md)**: All-in-one complete manual.
* 📋 **[Project Analysis & Architecture](docs/NIVA_PROJECT_DOCUMENTATION.md)**: 35-point comprehensive project breakdown.
* 🧩 **[Detailed Feature Documentation](docs/NIVA_FEATURE_DOCUMENTATION.md)**: Technical specifications for all 12 implemented features.
* 📱 **[Screen Documentation & Visuals](docs/NIVA_SCREEN_DOCUMENTATION.md)**: Screen-by-screen breakdown with embedded actual UI captures.
* 🗂️ **[Screen Inventory Table](docs/NIVA_SCREEN_INVENTORY.md)**: Complete registry of all 14 production UI states.
* 🔥 **[Firebase & Firestore Documentation](docs/NIVA_FIREBASE_DOCUMENTATION.md)**: Complete collection schemas, rules, and indexing.
* 🔒 **[Security & Access Control Documentation](docs/NIVA_SECURITY_DOCUMENTATION.md)**: Deep dive into auth, ownership, and defense-in-depth.
* 🧪 **[Testing & Verification Documentation](docs/NIVA_TESTING_DOCUMENTATION.md)**: Test suite results, coverage, and analysis evidence.
* 🖼️ **[Screenshots Directory](docs/screenshots/)**: Actual UI screenshots rendered at 390 x 844 (`01_splash.png` to `14_report.png`).

---

## Flutter Resources

* [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
* [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
* [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
* [Online documentation](https://docs.flutter.dev/)
