# Change Log 2026-08-20

## Task: Clean up llm_service.dart (one-shot explanation flow)

User review of `lib/services/llm_service.dart` surfaced stale/dead code from the
chat era. All four issues fixed in one commit.

### Changes

1. **Stale `_systemPrompt` default updated** — the default prompt still told the
   model it had access to the `generate_gua` function and to wrap responses in
   JSON, both long gone. Rewrote it for the one-shot tool-free flow. The
   `systemPrompt` field itself is kept — it is live, edited by the Settings
   prompt editor and injected as the `systemInstruction` when opening the chat.

2. **Removed dead `_fallbackContext`** — was only the `??` fallback when
   `guaGenerator` was null, but `model_selection_screen.dart:240-242` always
   wires it before explanations run. `generateExplanation` now uses
   `_guaGenerator!.formatContext(result)` directly.

3. **Confirmed settings prompt wiring** — the explanation prompt has two parts:
   the customizable system prompt (Settings menu → `systemPrompt` →
   `systemInstruction` in `openExplanationChat`) and the hardcoded user-message
   template (question + hexagram + language). Both are intentional; nothing to
   change.

4. **Dropped JSON response format to save tokens** — removed the
   "Wrap your final response in JSON" instruction from both the user prompt and
   `_systemPrompt`; removed `_extractJsonMessage` and the now-unused
   `dart:convert` import; return trimmed text directly.

### Verification
- `flutter analyze` — no new issues (only 2 pre-existing warnings)
- `flutter test` — 88 tests pass
- `flutter test -d windows integration_test/cast_and_browse_test.dart` — 2 tests pass

## Task: Load hexagrams from JSON assets (drop `gua` DB table)

User opted for the full refactor (previously deferred): remove the SQLite `gua`
table and read all 64 hexagrams directly from the bundled JSON assets.

### Changes
- **New `HexagramLoader`** (`lib/services/hexagram_loader.dart`): loads
  `assets/hexagrams/gua_<n>.json` into `Gua` objects (with an injectable loader
  for tests). Replaces `GuaSeeder` + `DatabaseService.getAllGua()`.
- **Deleted `GuaSeeder`** (`lib/services/gua_seeder.dart`) and its test.
- **DatabaseService** — removed the `gua` table, `createGua`/`getGua`/`getAllGua`
  CRUD, `_dropGuaColumns`, and bumped schema to v6 (migration drops any legacy
  `gua` table). DB now stores only `settings`.
- **Gua model** — removed `id`, `toMap`, `fromMap`, `copyWith` (no more DB row).
- **GuaGenerator** — takes `HexagramLoader` instead of `DatabaseService`.
- **QuestionFormScreen** — `GuaGenerator()` + optional injectable `guaGenerator`
  and `hexagramLoader` params (for tests).
- **HexagramBrowserScreen** — loads from `HexagramLoader` (optional injected
  `loader`); no longer takes a `DatabaseService`.
- **model_selection_screen / main** — `GuaGenerator()`; removed `GuaSeeder` from
  startup seeding.
- **db_inspector** — dumps `settings` only.
- **Tests** — rewrote `database_service_test` (settings only), `gua_generator_test`
  and `hexagram_browser_screen_test` (injected loader), `migration_v4_test` (v6
  gua-drop), `question_form_screen_test` (injected generator/loader); added
  `hexagram_loader_test`. Updated `Gua(id: ...)` usages across tests.
- **Docs** — AGENTS.md / README.md / spec.md updated: hexagrams come from JSON
  assets, DB stores only settings.

### Verification
- `flutter analyze` — only 1 pre-existing warning (`_selectedModel` unused)
- `flutter test` — 82 unit tests pass
- `flutter test -d windows integration_test/cast_and_browse_test.dart` — 2 pass

## Task: Explanation screen hexagram card opens the detail screen

Tapping the hexagram card on `ExplanationScreen` now opens
`HexagramDetailScreen`, matching the existing pattern on `CastResultScreen`.

### Changes
- `app/lib/screens/explanation_screen.dart`: wrapped the hexagram card in an
  `InkWell` that navigates to `HexagramDetailScreen(gua: gua)`; added a
  "Tap for details" hint and a chevron icon.
- `app/test/explanation_screen_test.dart`: updated the exact `第46卦` assertion
  to `textContaining` and added a test that tapping the hexagram card opens the
  detail screen.

### Verification
- `flutter analyze` — no new issues
- `flutter test` — 83 unit tests pass