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

## Task: Android must not show the local model picker (#86 follow-up)

- AppConfig.firebaseEnabled now defaults to **true on Android** (and false
  elsewhere); FIREBASE_ENABLED=true|false still overrides it. useRemoteBackend
  therefore stays true on Android even when the build omits the local config.
- Added FirebaseConfigErrorScreen (EN/ZH) shown when the remote edition cannot
  initialize Firebase; Android never falls back to ModelSelectionScreen.
- main.dart records the bootstrap result and routes to the error screen instead
  of the consent/home flow when Firebase is unavailable.
- Rebuilt and verified on emulator-5554: with the local file -> consent/Ask;
  without it -> "Firebase is not configured" (no local model picker).
- Tests: new error-screen widget test; updated config/bootstrap expectations;
  full suite 274 passing.

## Task: Hide the local model section on Android (#86)

- `SettingsScreen` hides the Model section by default in the remote edition
  (`AppConfig.useRemoteBackend`); desktop still shows it. Added an optional
  `showModelSection` override for tests.
- The local model-path/remove-file load is skipped when the section is hidden.
- Tests: new remote-hidden test; model-section tests opt in explicitly; full
  suite 275 passing.
- Verified on `emulator-5554` (Chinese UI): Preference shows Language, Theme,
  Prompts, Privacy, About - no Model section.
