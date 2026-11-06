# Manual Firebase AI smoke tests

These tests are **manual only** — `flutter test` (and CI) does not run them.

They make real Firebase AI Logic (Gemini) calls, so they need:

- an Android device/emulator,
- `app/firebase.local.json` (git-ignored) with the restricted API key and
  project/app IDs,
- a registered App Check debug token, ideally pinned with
  `FIREBASE_APPCHECK_DEBUG_TOKEN` (otherwise every install generates a new
  token that must be registered).

## Run

```bash
cd app
flutter test -d emulator-5554 \
  --dart-define-from-file=firebase.local.json \
  integration_test/manual/firebase_ai_smoke_test.dart
```

## What it checks

- Firebase initializes from the dart-define options (no `google-services.json`).
- App Check passes.
- The restricted key + `firebasevertexai.googleapis.com` are reachable.
- A Gemini explanation comes back and is cleaned (no `<|channel>` /
  `<|endoftext|>` tags).

The deterministic backend logic (prompt building, memory JSON, channel
cleanup, error fallbacks) is covered by `test/firebase_ai_backend_test.dart`
with a mocked `FirebaseContentGenerator`.
