# I-Ching Consultant — Agent Guidelines

## 1. Tech Stack & Constraints

| Layer        | Technology                           |
|--------------|--------------------------------------|
| Framework    | Flutter                              |
| Language     | Dart 3.12+                           |
| Database     | SQLite via `sqflite` / `sqflite_ffi` |
| LLM Runtime  | `flutter_gemma`                      |
| Model        | Gemma 4 / Qwen3 0.6B (downloaded at first run) |
| State        | StatelessWidget / StatefulWidget     |
| Testing      | `flutter_test` with `sqflite_ffi` (in-memory DB) |
| Linting      | `flutter_lints` (default rules)      |

**Key constraint:** All LLM inference runs locally on-device. No internet access required after model download. No telemetry, no analytics, no external API calls.

---

## 2. Design Approach

1. **One function per prompt.** If you think there are multiple things to implement, confirm with the user to split the tasks.

2. **Tests per function.** Every function must have a corresponding unit test. Verify all existing tests pass after each change. If existing tests fail, ask for confirmation before assuming the test is wrong.

3. **Don't assume.** Ask the user if anything is unclear about requirements, design, or implementation details.

4. **Log changes.** Write the prompt, thinking process, and all file changes into `logs/change_log_yyyy_mm_dd.md`.

---

## 3. Project Structure

```
iching/
├── app/                          # Flutter application
│   ├── lib/
│   │   ├── data/                 # Static data (model_catalog.dart, trigram_hexagram_data.dart)
│   │   ├── models/               # Dart data models
│   │   │   ├── gua.dart
│   │   │   ├── hexagram_content.dart
│   │   │   ├── language_preference.dart
│   │   │   ├── model_info.dart
│   │   │   ├── trigram_hexagram.dart
│   │   │   └── yao_line_type.dart
│   │   ├── screens/              # UI screens
│   │   │   ├── cast_result_screen.dart
│   │   │   ├── explanation_screen.dart
│   │   │   ├── hexagram_browser_screen.dart
│   │   │   ├── hexagram_detail_screen.dart
│   │   │   ├── model_selection_screen.dart
│   │   │   ├── prompt_editor_screen.dart
│   │   │   ├── question_form_screen.dart
│   │   │   └── settings_screen.dart
│   │   ├── services/             # Business logic
│   │   │   ├── database_service.dart
│   │   │   ├── fake_llm_service.dart
│   │   │   ├── gua_generator.dart
│   │   │   ├── gua_seeder.dart
│   │   │   └── llm_service.dart
│   │   └── main.dart
│   ├── assets/hexagrams/         # Individual hexagram JSON files
│   ├── test/
│   │   ├── cast_result_screen_test.dart
│   │   ├── database_service_test.dart
│   │   ├── explanation_screen_test.dart
│   │   ├── gua_generator_test.dart
│   │   ├── hexagram_browser_screen_test.dart
│   │   ├── hexagram_content_test.dart
│   │   ├── hexagram_loader_test.dart
│   │   ├── hexagram_detail_screen_test.dart
│   │   ├── language_preference_test.dart
│   │   ├── migration_v4_test.dart
│   │   ├── prompt_editor_screen_test.dart
│   │   ├── question_form_screen_test.dart
│   │   ├── settings_screen_test.dart
│   │   ├── trigram_hexagram_data_test.dart
│   │   └── widget_test.dart
│   └── pubspec.yaml
├── logs/                         # Change logs
├── spec.md                       # Full project specification
└── AGENTS.md                     # This file
```

---

## 4. Code Conventions

### Models

- Each model has `copyWith()`, `toMap()`, and `factory ModelName.fromMap()`.
- DB column names use `snake_case`. Dart fields use `camelCase`.
- Override `toString()`, `==`, and `hashCode` for every model.
- Use `?` nullable fields for DB auto-generated IDs (`int? id`).

### Services

- Services are plain Dart classes injected via constructor.
- DatabaseService uses a `_customPath` constructor param for test in-memory DBs (`:memory:`).
- Catch platform-specific errors gracefully (e.g., `DatabaseService.create()` returns `null` on unsupported platforms).
- `LlmService.generateExplanation()` is a one-shot call (no function calling, no history) on a tool-free session.

### Naming

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/functions: `camelCase`
- Private members: `_camelCase`
- Enums: `PascalCase` with `camelCase` values

### Imports

- `package:app/...` for cross-file imports (not relative paths).
- Order: Flutter SDK → packages → project files.

### Async

- Use `Future<T>` and `async/await` consistently.
- Catch specific exceptions, not bare `catch`.

---

## 5. Testing Conventions

- Use `sqflite_ffi` for tests: call `sqfliteFfiInit()` and set `databaseFactory = databaseFactoryFfi` in `setUpAll`.
- Create `DatabaseService(databasePath: ':memory:')` for isolated test DBs.
- Always `close()` the database in `tearDown`.
- Hexagrams are loaded from JSON assets via `HexagramLoader` (inject a loader in tests); the DB only stores settings.
- Use `group()` to organize related tests.
- Widget tests must wrap the app widget directly (e.g., `MyApp(databaseService: db)`).

**Run tests:**
```bash
cd app
flutter test                    # Unit + widget tests
flutter test -d windows integration_test/all_tests.dart  # Integration tests (Windows desktop)
```

**Before every commit** run `flutter test && flutter test -d windows integration_test/cast_and_browse_test.dart` to verify nothing is broken.

---

## 6. Database Schema

The database stores **only settings**. Hexagrams are loaded directly from JSON
assets (`assets/hexagrams/gua_<n>.json`) via `HexagramLoader` — there is no
`gua` table.

### settings
| Column       | Type    | Notes                       |
|-------------|---------|-----------------------------|
| key          | TEXT    | PK (e.g. language, system_prompt, selected_model_key) |
| value        | TEXT    |                            |

---

## 7. Key Patterns

- **GuaGenerator** uses `GeneratorMethod` enum (`manual`, `systemGenerated`) with different context prompt headers per method. Casts 6 yao lines via the three-coin method (`YaoLineType`: 老陰/少陽/少陰/老陽), resolves the hexagram via `TrigramHexagramData`. Hexagrams are loaded from JSON assets through `HexagramLoader` (no DB table).
- **Consultation flow** (form-based, low token usage): QuestionFormScreen → submit → `GuaGenerator.generateRandom()` → CastResultScreen (卦象 + per-line types) → "Get Explanation" → `LlmService.generateExplanation()` (one-shot, no multi-turn history, tool-free) → ExplanationScreen.
- **LlmService** wraps flutter_gemma. `generateExplanation()` opens its own tool-free session (`openExplanationChat()`), sends one prompt combining hexagram context + question + language preference, and returns the response.
- **Language & prompts**: `LanguagePreference` (en/cn) and a custom system prompt are stored in the `settings` table and injected into the explanation prompt.
- **Hexagram data** is read straight from the bundled JSON assets by `HexagramLoader`. The DB migration to v6 drops any legacy `gua` table.

---

## 8. Commit Messages

Follow conventional commits format: `type: short description`

Examples: `feat: add hexagram card with visual 6-line yao pattern`, `fix: hexagram broken lines now render as two segments`, `refactor: centralize model config into instance variables`
