# Change Log 2026-11-03

## Task: Personalized greeting on the Ask tab (#25)

Show a short personalized greeting on the first page, built from the agent
memory (`feeling` / per-topic feelings / `facts` / `preferences`).

### Backend coverage (local + Gemini editions)

The greeting reads the locally stored `AgentMemory` and composes localized
templates — **no LLM call** — so it is backend-agnostic and works identically
for the on-device `flutter_gemma` edition and the Gemini (Firebase AI Logic)
edition. It appears whenever the active backend has produced memory
(`extractMemory`; the remote implementation is #85).

### Changes

- New `app/lib/services/agent_greeting.dart`
  - `buildAgentGreeting(memory, l10n)` returns `null` for empty memory, else
    “Welcome back.” plus the overall feeling (or the first per-topic feeling,
    fact, or preference, in that order).
- `app/lib/screens/question_form_screen.dart`
  - Loads agent memory on first build and again when returning from the
    consultation flow, then shows the greeting under the Ask title.
- `app/lib/l10n/app_localizations.dart`
  - New `greetingWelcome`, `greetingWithFeeling`, `greetingRemember` (EN + zh-TC).
- Tests
  - `app/test/agent_greeting_test.dart` — empty memory, overall feeling,
    per-topic fallback, fact/preference fallback, zh localization.
  - `app/test/question_form_screen_test.dart` — greeting shown from a fake
    memory DB (no `llmService`), and hidden when memory is empty.

### Notes

- Template-based on purpose: instant, zero tokens, and independent of the
  backend. An LLM-written greeting can be layered on top of the `LlmBackend`
  abstraction later if desired.
- A real-DB widget test with `pumpAndSettle` hung under sqflite-ffi; the widget
  test uses a small `_MemoryDb` fake instead.

### Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (236 pass)

## Task: Switch interpreter on the cast-result screen (#22)

Add an interpreter picker above “Get Explanation”. The selected interpreter is
persisted in `settings` (`selected_interpreter`) and its system prompt is used
for the explanation; a custom system prompt (developer mode) still takes
precedence.

### Changes

- New `app/lib/models/interpreter.dart` — key, EN/zh names, description, avatar
  icon, system prompt.
- New `app/lib/data/interpreter_catalog.dart` — three built-in interpreters
  (Compassionate Counselor, Classical Scholar, Practical Advisor) plus the
  default and settings key.
- New `app/lib/widgets/interpreter_picker.dart` — avatar + name choice chips.
- `app/lib/screens/cast_result_screen.dart` — `_ExplanationLauncher` shows the
  picker, persists the selection, and opens `ExplanationScreen` with the
  effective system prompt.
- `app/lib/screens/explanation_screen.dart` — accepts an optional `systemPrompt`
  and applies it before generating.
- `app/lib/l10n/app_localizations.dart` — `interpreter` label (EN + zh-TC).
- Tests: catalog, picker, cast-result persistence, and explanation system
  prompt.

### Notes

- Avatar icons are placeholders for the requested “profile picture”; real
  artwork can be dropped into the catalog later.
- The custom system prompt (developer mode) wins over the interpreter prompt;
  in production the read-only prompt is typically empty, so the interpreter is
  used.
- A “second opinion” / re-run flow is intentionally out of scope (the author
  marked it optional / separate).

### Feature flag

The picker is behind `AppConfig.interpreterSelectionEnabled`: **off by default**,
enabled only on Windows (`!kIsWeb && defaultTargetPlatform ==
TargetPlatform.windows`). Override with
`--dart-define=ENABLE_INTERPRETER_SELECTION=true|false`. When off, the
Interpreter label/picker are hidden and the explanation uses the custom prompt
or the backend default.

### Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (255 pass)
