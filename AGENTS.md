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
│   │   ├── data/                 # Static data (hexagram_data.dart)
│   │   ├── models/               # Dart data models
│   │   │   ├── chat_message.dart
│   │   │   ├── conversation.dart
│   │   │   └── gua.dart
│   │   ├── screens/              # UI screens
│   │   │   ├── chat_screen.dart
│   │   │   ├── conversation_detail_screen.dart
│   │   │   ├── model_download_screen.dart
│   │   │   └── settings_screen.dart
│   │   ├── services/             # Business logic
│   │   │   ├── database_service.dart
│   │   │   ├── gua_generator.dart
│   │   │   ├── gua_seeder.dart
│   │   │   └── llm_service.dart
│   │   ├── widgets/              # Reusable UI components
│   │   │   └── gua_card.dart
│   │   └── main.dart
│   ├── test/
│   │   ├── database_service_test.dart
│   │   ├── gua_generator_test.dart
│   │   ├── gua_seeder_test.dart
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
- LLM function calling uses the `generate_gua` tool with optional `intent` parameter.

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
- Seed gua data with `GuaSeeder` before tests that need gua records.
- Use `group()` to organize related tests.
- Widget tests must wrap the app widget directly (e.g., `MyApp(databaseService: db)`).

**Run tests:**
```bash
cd app
flutter test                    # Unit + widget tests
flutter test -d windows integration_test/all_tests.dart  # Integration tests (Windows desktop)
```

**Before every commit** run `flutter test && flutter test -d windows integration_test/all_tests.dart` to verify nothing is broken.

---

## 6. Database Schema

### conversations
| Column       | Type    | Notes                |
|-------------|---------|----------------------|
| id          | INTEGER | PK, AUTOINCREMENT    |
| title       | TEXT    | Auto-generated (date-time) |
| created_at  | TEXT    | ISO 8601             |
| updated_at  | TEXT    | ISO 8601             |
| last_gua_id | INTEGER | FK to gua.id (nullable) |

### chat_messages
| Column          | Type    | Notes                          |
|----------------|---------|--------------------------------|
| id             | INTEGER | PK, AUTOINCREMENT              |
| conversation_id| INTEGER | FK → conversations.id          |
| sender         | TEXT    | "user" or "system"             |
| message        | TEXT    |                                |
| timestamp      | TEXT    | ISO 8601                       |

### gua
| Column       | Type    | Notes                |
|-------------|---------|----------------------|
| id          | INTEGER | PK, AUTOINCREMENT    |
| gua_code    | INTEGER | 1-64                 |
| gua_name    | TEXT    | e.g. "乾 (qián)"     |
| gua_content | TEXT    | Full hexagram text   |
| gua_summary | TEXT    | Reflection prompt    |
| source      | TEXT    | Generator type       |

---

## 7. Key Patterns

- **GuaGenerator** uses `GeneratorMethod` enum (`userRequested`, `randomCast`, `automatic`) with different context prompt headers per method.
- **ChatMessage** uses string `id` for UI keys (`msg_0`, `db_{rowId}`) and separate nullable `dbId` for the database PK.
- **LlmService** wraps flutter_gemma, supports function calling (`generate_gua` tool), handles thinking tag stripping, JSON message extraction, and proactive context compression.
- **Gua seeding** happens at startup via `GuaSeeder.seedIfNeeded()` (only seeds if gua table is empty).

---

## 8. Commit Messages

Follow conventional commits format: `type: short description`

Examples: `feat: add hexagram card with visual 6-line yao pattern`, `fix: hexagram broken lines now render as two segments`, `refactor: centralize model config into instance variables`
