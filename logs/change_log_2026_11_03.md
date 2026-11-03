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
