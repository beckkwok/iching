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

## Task: Firebase project configuration (#84 follow-up)

- Logged the Firebase CLI in as the account that owns **`iching-bb741`** (the
  project was hidden under the previous CLI session).
- Set the Android `applicationId` to **`com.beckkwok.iching`**.
- Ran `flutterfire configure --project=iching-bb741 --platforms=android --yes`:
  registered the Android app, generated `lib/firebase_options.dart`,
  `android/app/google-services.json` and `firebase.json`, and applied the
  `com.google.gms.google-services` Gradle plugin.
- Renamed the bootstrap test to reflect that Firebase initialization is
  unavailable in pure unit tests.
- `flutter build apk --debug --dart-define=FIREBASE_ENABLED=true` succeeds.

### App Check next step

Run the app on an Android device with `FIREBASE_ENABLED=true`; copy the App
Check **debug token** from the log and register it in Firebase Console →
Security → App Check → Apps → *Manage debug tokens*. For release, configure
Play Integrity (requires the app to be registered with Google Play).

### Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (259 pass)
- `flutter build apk --debug --dart-define=FIREBASE_ENABLED=true` — succeeds

## Task: FirebaseAiBackend (Gemini) (#85)

Part of #82. Remote backend using Firebase AI Logic.

### Changes

- New `app/lib/services/firebase_ai_backend.dart` — `FirebaseAiBackend`:
  - `generateExplanation` and `extractMemory` via
    `FirebaseAI.googleAI().generativeModel(...).generateContent(...)`.
  - Reuses `LlmPromptStrategy` (prompt building/cleaning) and
    `GuaGenerator.formatContext` for the hexagram context.
  - JSON response mode for memory extraction.
  - Errors are caught (fallback explanation / null memory).
  - Injectable `FirebaseContentGenerator` for tests (no network).
- `LlmBackend` now exposes `systemPrompt` and `guaGenerator`, so local and
  remote backends share the same facade.
- `LlmService.systemPrompt` delegates to the active backend; `guaGenerator`
  updates both the local and active backends.
- `AppConfig.firebaseModel` (`--dart-define=FIREBASE_AI_MODEL`, default
  `gemini-3.8-flash`).
- Tests: `app/test/firebase_ai_backend_test.dart` — prompt/context, custom
  system prompt, channel cleanup, JSON memory, failure fallbacks.

### Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (264 pass)

### Next

#86 wires backend selection (Android remote / Windows local), skips the local
model on Android, and adds the consent/error UX.

## Task: Revoke exposed Firebase API key + remove config

- Deleted the exposed Android API key (`Android key (auto created by
  Firebase)`, ending `dgk4`) from project `iching-bb741` via the Cloud API Keys
  API.
- Removed `app/android/app/google-services.json`.
- Reverted `app/lib/firebase_options.dart` to a keyless stub that throws until
  reconfigured.
- Removed the `com.google.gms.google-services` Gradle plugin from
  `android/settings.gradle.kts` and `android/app/build.gradle.kts`.
- Left `app/firebase.json` (project/app IDs only, no key) in place.
- Purged the key from `main` and reachable branch history with
  `git filter-repo`, then force-pushed. GitHub may still retain old PR
  refs/caches; the key is revoked either way.

### Notes

- Firebase stays disabled (`FIREBASE_ENABLED` defaults to false) until a new,
  restricted API key is created and `flutterfire configure` is run again.

### Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (259 pass)
- `flutter build apk --debug` — succeeds without the Firebase config

## Task: Mandatory secret-handling rule in AGENTS.md

Added rule 5 to **Design Approach**: if any configuration, asset, generated
file, or log contains an API key, token, secret, or credential (e.g.
`google-services.json`, `firebase_options.dart`, `.env`, `key.properties`, CI
secrets), the agent must stop and alert the user before reading/committing/
pushing/sharing. Never commit secrets; recommend revoking/rotating exposed ones
and removing them from the config (and history if needed).
