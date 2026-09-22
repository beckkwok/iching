# Change Log 2026-09-22

## Task: Default model + auto-download on first launch (issue #4)

Issue #4: model selection/download is a development feature; production should
have a model available by default. Decision (see issue comment): **Option B** —
auto-download the default model on first launch, keep the selection grid for
development, and defer the Play Asset Pack (offline-from-install) to a later
release.

### Changes
- **`lib/config/app_config.dart`** (new) — `AppConfig.allowModelSelection`
  (`--dart-define=ALLOW_MODEL_SELECTION`, defaults to `kDebugMode`).
- **`lib/data/model_catalog.dart`** — `defaultModelKey = 'qwen3'` and
  `defaultModel` (Qwen3-0.6B).
- **`lib/screens/model_selection_screen.dart`**:
  - New `allowSelection` (default `AppConfig.allowModelSelection`) and an
    injectable `llmServiceFactory` (tests).
  - Startup: saved model → load/download it; else, if `allowSelection` → grid;
    else → auto-select + download `ModelCatalog.defaultModel`.
  - Removed the old Gemma-4-E2B backward-compat fallback.
  - Added the internet-usage notice to the download and selection screens.
- **`lib/l10n/app_localizations.dart`** — added `internetNotice`; removed the
  now-unused `autoDetectFailed`.
- **`android/app/src/main/AndroidManifest.xml`** — added the `INTERNET`
  permission (used only to download the model).

### Privacy
Internet is used only to download the model; no personal data is uploaded. This
is surfaced to the user via the new notice and matches the privacy screen.

### Tests
- `model_selection_screen_test.dart`: production auto-downloads the default
  model; production loads an installed model without downloading.
- `model_catalog_test.dart`: `defaultModel` resolves to the configured key.

### Platform verification
- **Windows**: real Qwen3-0.6B model loaded and generated an explanation
  (prefill ~704 ms, ~55 chunks/s). ✅
- **Android**: the app builds, installs, and runs; the model is found and set
  active. ❌ The **x86_64 emulator cannot execute `.litertlm`** —
  `flutter_gemma_litertlm` requires an **arm64-v8a** device:
  `Unsupported operation: flutter_gemma .litertlm models require an arm64-v8a
  Android device (got x86_64)`. Android real-model verification needs a physical
  arm64 device.

### Verification
- `flutter analyze` — no new issues
- `flutter test` — 117 unit tests pass
- `flutter test -d windows integration_test/cast_and_browse_test.dart` — 2 pass
