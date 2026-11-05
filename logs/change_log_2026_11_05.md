# Change Log 2026-11-05

## Task: Firebase project bootstrap + App Check (#84)

Part of #82. Code-side bootstrap only; the Firebase project/config still needs
to be created in the console and generated with `flutterfire configure`.

### Changes

- `app/pubspec.yaml` — added `firebase_core ^5.1.0`, `firebase_ai ^5.1.0`,
  `firebase_app_check ^0.5.1`.
- `app/lib/firebase_options.dart` (new) — placeholder options that throw until
  `flutterfire configure` replaces the file.
- `app/lib/services/firebase_bootstrap.dart` (new) — initializes Firebase +
  App Check on Android/iOS/macOS only; debug providers in debug builds,
  Play Integrity / App Attest in release; skips Windows/Linux/web and catches
  failures so the app can still run.
- `app/lib/config/app_config.dart` — `firebaseEnabled` (`--dart-define=
  FIREBASE_ENABLED=true`), **off by default** until the project is configured.
- `app/lib/main.dart` — calls `initializeFirebase()` when enabled.
- Android build: Kotlin Gradle plugin `2.2.20 → 2.4.0` (the Firebase Auth
  AAR metadata requires 2.4) and migrated `kotlinOptions.jvmTarget` to the
  `kotlin { compilerOptions { jvmTarget = … } }` DSL.
- `app/test/firebase_bootstrap_test.dart` (new) — disabled by default, platform
  gating (Windows unsupported), graceful failure when unconfigured.

### Manual next steps

1. Install the Firebase CLI and FlutterFire CLI; `firebase login`.
2. Create/select a Firebase project; finalize the application ID (the repo still
   uses the placeholder `com.example.app`).
3. From `app/`, run `flutterfire configure` (Android/iOS/macOS).
4. Register the App Check debug token for development; configure Play
   Integrity / App Attest for release.
5. Build with `--dart-define=FIREBASE_ENABLED=true`, then proceed to #85.

### Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (259 pass)
- `flutter build apk --debug` — succeeds
