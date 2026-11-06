# Change Log 2026-11-06

## Task: Summarize the agent memory when it grows too long (#49)

- Added an approximate token budget to `AgentMemory`
  (`maxApproximateTokens = 1000`, ~3 chars/token) and `toSummaryText`.
- `LlmBackend.summarizeMemory(AgentMemory)` implemented by the local and
  Firebase backends via a shared `summarizeMemoryPrompt`; `LlmService`
  delegates; `FakeLlmService` can return a canned summary.
- `MemoryExtraction` now carries the per-topic `feelings` map so a summary
  keeps them.
- `DatabaseService.replaceAgentMemory` overwrites the single profile row.
- `ExplanationScreen` summarizes and replaces the profile after a merge when
  it exceeds the budget.
- Tests: AgentMemory budget/text, DB replace, Firebase backend summarize,
  service delegation, and the over-long-memory trigger.

### Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (273 pass)

## Task: Localize and merge the Ask greeting

- The Ask screen merges the personalized greeting with the question prompt into
  one text (greeting + prompt) instead of two separate labels.
- Memory extraction and summarization now take a `LanguagePreference` and
  instruct the LLM to write profile values in the selected language. The
  explanation flow passes the active language for both.
- If an existing profile was stored in the other script, `QuestionFormScreen`
  re-summarizes it once in the selected language and replaces the row, so the
  greeting is localized immediately (no mixed-language greeting).
- Added `memoryGreetingMatchesLocale`; tests for prompt language, delegation,
  the screen's language pass-through, localized/merged greeting, and profile
  re-localization. 277 tests passing.
- Verified on `emulator-5554`: the stored English profile was re-localized and
  the Ask screen shows one Chinese greeting + prompt paragraph.
