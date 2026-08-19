# Change Log — 2026-06-29

## Prompt
Build the Model Selection Screen feature: redesign the startup flow with a card-based model picker, persist the choice in a new SQLite settings table, auto-detect existing models, and add a "Remove Model File" button in settings.

## Thinking

### Problem
The old `ModelDownloadScreen` hardcoded a single model (Gemma 4 E2B) and offered no choice. Users had no way to pick from the 6 available models (Gemma 4 E2B, Gemma 4 E4B, DeepSeek R1, Gemma 3 1B, Qwen2.5, Qwen3). The model file picker in Settings was unnecessary once the model is locked in.

### Design Decisions
1. **ModelInfo data class** — Clean metadata record mirroring the user's model table. Placed in `models/model_info.dart`.
2. **ModelCatalog** — Static catalog of all 6 models with their keys, URLs, and flutter_gemma types. Placed in `data/model_catalog.dart`.
3. **Settings table** — Key-value table in SQLite (`settings(Key TEXT PK, Value TEXT)`). DB version bumped from 1 → 2 with migration.
4. **LlmService refactor** — Constructor now takes `ModelInfo` instead of hardcoded defaults. `modelDisplayName`, `modelSize`, `modelType`, `isThinking`, `filename`, `downloadUrl` all come from the ModelInfo object.
5. **Startup flow**:
   - Check settings for `selected_model_key`
   - If found → look up ModelInfo, check file existence
   - File exists → auto-proceed to chat
   - File missing → download that model (not re-select)
   - If no key → check old default `gemma-4-E2B-it.litertlm` for backward compat
   - Otherwise → show selection card grid
6. **ModelSelectionScreen** — Combines selection grid + download progress + error handling in one screen. No HuggingFace token field (user wanted download immediately).
7. **Settings screen** — Read-only model display (Model, File Name, Full Path). "Remove Model File" button deletes file + clears setting → redirects to ModelSelectionScreen.
8. **FakeLlmService** — Updated to pass a default ModelInfo since constructor now requires it.

### Key constraints satisfied
- Model cannot be changed after selection (remove + re-select flow)
- Optional HuggingFace token removed (download immediately)
- File picker removed from settings
- Auto-detect existing model files

## Files Changed

### Created
- `app/lib/models/model_info.dart` — Metadata class for available models
- `app/lib/data/model_catalog.dart` — Static catalog of 6 models
- `app/lib/screens/model_selection_screen.dart` — Card grid selection + download screen

### Modified
- `app/lib/services/database_service.dart` — Added `settings` table, CRUD methods, version bump to 2
- `app/lib/services/llm_service.dart` — Constructor takes `ModelInfo`, all fields derived from it
- `app/lib/services/fake_llm_service.dart` — Constructor passes default ModelInfo
- `app/lib/screens/settings_screen.dart` — Read-only model info, "Remove Model File" button
- `app/lib/screens/chat_screen.dart` — Pass `databaseService` to `SettingsScreen`
- `app/lib/main.dart` — Use `ModelSelectionScreen` instead of `ModelDownloadScreen`
- `app/test/database_service_test.dart` — Added 5 settings CRUD tests
- `app/integration_test/all_tests.dart` — Updated settings screen test expectations

### Deleted
- `app/lib/screens/model_download_screen.dart` — Replaced by `model_selection_screen.dart`

## Test Results
- **Unit tests:** 43/43 passed
- **Integration tests:** 10/10 passed
