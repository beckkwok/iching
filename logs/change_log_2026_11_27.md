# Change Log — 2026-11-27

## Task: sideloaded release LLM calls fail

### Symptom

The 1.1.0 release APK opened the remote/Gemini flow and showed the new prompt,
but `generateExplanation` returned “The explanation could not be generated.”
The device log showed a Play Integrity token request.

### Cause

The release APK is signed with the local debug key and sideloaded, so Play
Integrity cannot attest it. App Check therefore rejects the release build's
Firebase AI requests. Debug builds use `AndroidDebugProvider` and work.

### Fix

- Added `APP_CHECK_DEBUG=true` support in `firebase_bootstrap.dart`: when set,
  a release build uses `AndroidDebugProvider` with the pinned
  `FIREBASE_APPCHECK_DEBUG_TOKEN` instead of Play Integrity.
- This is for local/sideloaded release APKs only; Play Store builds must keep
  the flag off and use Play Integrity.
- Added a unit test for the debug-provider selection and documented the flag in
  `docs/firebase-setup.md`.

### Verification

- `flutter analyze`: 3 pre-existing infos only.
- `flutter test`: 289 passing.
- Built a release APK with
  `--dart-define=APP_CHECK_DEBUG=true` for device testing.
