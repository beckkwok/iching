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

## Task: Mobile UI redesign — Phase 1 (issue #6)

Portrait-first shell with a bottom navigation bar; header bars removed.

### Changes
- Added `forui: ^0.25.0` (newest compatible with Flutter 3.44) and
  `rive: ^0.13.20` (the version matching the Rive sample's API).
- Copied the sample's `icons.riv`/`menu_button.riv` to `assets/RiveAssets/`.
- **`lib/screens/home_shell.dart`** (new) — Material `Scaffold` +
  `forui` `FBottomNavigationBar` hosting five lazily-built tabs (History,
  Profile, Ask, Browse, Preference) with Rive-animated icons
  (`assets/RiveAssets/icons.riv`). `HomeShell.enableRiveAnimations` is disabled
  in widget tests (no Rive native library there) with a Material-icon fallback.
- **`lib/screens/history_screen.dart`**, **`profile_screen.dart`** (new
  placeholders — real work tracked in issues #8 and #3).
- Removed the `AppBar` from `QuestionFormScreen`, `HexagramBrowserScreen`, and
  `SettingsScreen`; removed the now-redundant settings menu and "Browse
  Hexagrams" button from the form.
- `main.dart` — wrapped `MaterialApp` in `forui` `FTheme`.
- `ModelSelectionScreen` now proceeds to `HomeShell` after the model loads.

### Verification
- `flutter analyze` — clean
- `flutter test` — 118 unit tests pass
- **Android** (x86_64 emulator): shell + Rive nav smoke test passed ✅
- **Windows**: ❌ blocked — the `rive_common` plugin hardcodes the **ClangCL**
  VS toolset, which isn't installed (`error MSB8020`). Windows builds need the
  "C++ Clang Compiler for Windows" component. Non-interactive install attempt
  returned exit 5007 (elevation required).

## Task: Remove Rive from the bottom navigation

Rive was only used for the five bottom-nav icons in `HomeShell`. It was
unstable on Windows (the runtime crashed with an access violation even with the
0.14 `rive_native` backend), so it was removed in favour of pure-Flutter
animated icons.

### Changes
- Removed the `rive` dependency and the `assets/RiveAssets/` entry from
  `pubspec.yaml`; deleted the `.riv` assets.
- `HomeShell` now uses Material icons with a small scale/tint animation
  (`TweenAnimationBuilder`) on the active tab — no native animation dependency.
- Dropped `HomeShell.enableRiveAnimations` and the Rive load/controller code.
- Updated tests and docs.

### Verification
- `flutter analyze` — clean
- `flutter test` — 118 tests pass
- `flutter build windows --debug` + launch — builds and stays up ✅

## Task: Pin the LLM engine versions (fix "Model may be invalid")

A `flutter pub upgrade` had bumped the LLM runtime
(`flutter_gemma 1.1.2 → 1.9.0`, `flutter_gemma_litertlm 1.0.2 → 1.8.0`), which
failed to load the bundled `.litertlm` model
(`BackendInitException: all FFI backends failed … Model may be invalid`).

### Changes
- Pinned `flutter_gemma: 1.1.2` and `flutter_gemma_litertlm: 1.0.2` in
  `pubspec.yaml` (with a comment explaining why).

### Verification
- `flutter analyze` — clean
- `flutter test` — 118 tests pass
- Real model on Windows: loads and generates an explanation ✅
