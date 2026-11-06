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
