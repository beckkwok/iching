# Firebase setup (secret-free)

The app reads Firebase config from **build-time environment values**. No API
key, `google-services.json`, or generated `firebase_options.dart` is committed.

## Local development

1. Create a **restricted API key** in Google Cloud Console → APIs & Services →
   Credentials (project `iching-bb741`):
   - **Application restriction:** Android apps → package
     `com.beckkwok.iching` + SHA-256 fingerprint(s) (debug keystore now; add the
     Play signing fingerprint before release).
   - **API restriction:** Gemini Developer API + the Firebase APIs used
     (App Check / Installations), once verified.
2. Copy the example and fill it in (it is git-ignored):
   ```bash
   copy app/firebase.local.example.json app/firebase.local.json
   ```
   | Key | Value |
   | --- | --- |
   | `FIREBASE_ENABLED` | `"true"` |
   | `FIREBASE_API_KEY` | the restricted key |
   | `FIREBASE_APP_ID` | Firebase console → Project settings → Your apps |
   | `FIREBASE_MESSAGING_SENDER_ID` | project sender ID |
   | `FIREBASE_PROJECT_ID` | `iching-bb741` |
3. Run/build with the file:
   ```bash
   cd app
   flutter run --dart-define-from-file=firebase.local.json
   flutter build apk --release --dart-define-from-file=firebase.local.json
   ```

`app/firebase.local.json` is **git-ignored**. Never commit it.

Android always uses the remote edition. If you build/run without the file, the
app shows a **"Firebase is not configured"** screen (not the local model
picker); desktop builds still use the local model. When launching from an IDE,
add `--dart-define-from-file=firebase.local.json` to the run configuration's
additional arguments.

## CI

Write `app/firebase.local.json` from a repository secret before building, or
pass the values with individual `--dart-define` flags.

## App Check

- **Debug:** run the app, copy the App Check debug token from the logs, and
  register it in Firebase Console → Security → App Check → Apps → *Manage debug
  tokens*.
- **Release:** enable Play Integrity (the app must be registered with Google
  Play).

## Notes

- Do **not** run `flutterfire configure` or commit `google-services.json` / a
  generated `firebase_options.dart`. The committed `firebase_options.dart` is
  keyless and reads the environment.
- The Firebase API key is technically a public project identifier, but the
  local-file approach keeps it out of git regardless.

## Optional environment keys

- `FIREBASE_AI_MODEL` — Gemini model name (default `gemini-3.5-flash-lite`). `gemini-3.8-flash` may be overloaded.
- `FIREBASE_APPCHECK_DEBUG_TOKEN` — a fixed App Check debug token for emulators/CI (register it once; otherwise every install generates a new token).

## Tests

`FirebaseAiBackend` is covered by `test/firebase_ai_backend_test.dart`, which
injects a mock `FirebaseContentGenerator` — no network, no model download, no
App Check. Run the normal suite:

```bash
cd app
flutter test
```

## Manual smoke test (optional)

A real Gemini call on a device/emulator — **not** part of `flutter test`/CI:

```bash
cd app
flutter test -d emulator-5554 --dart-define-from-file=firebase.local.json integration_test/manual/firebase_ai_smoke_test.dart
```

See `app/integration_test/manual/README.md`.

## Cost controls

- Default model: `gemini-3.5-flash-lite` (free-tier friendly); override with `FIREBASE_AI_MODEL`.
- Explanations cap output at `maxOutputTokens: 512` (`FirebaseAiBackend`).
- Set **budget alerts** and **spend caps** in Google Cloud for the project.
- Monitor usage in the Firebase/Google Cloud console.
- App Check + the default per-instance rate limits protect against abuse.

## Verification checklist (manual)

- [ ] Android device/emulator with `app/firebase.local.json`.
- [ ] App Check debug token registered (or pinned via `FIREBASE_APPCHECK_DEBUG_TOKEN`).
- [ ] `integration_test/manual/firebase_ai_smoke_test.dart` passes (real Gemini call, no channel/control tags).
- [ ] In-app: consent → Ask → "Get Explanation" returns a Gemini explanation; the consultation appears in History with the full record.
- [ ] Windows: `flutter run` uses the local model (no Firebase).
