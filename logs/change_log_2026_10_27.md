# Change Log 2026-10-27

## Task: Allow remote LLM providers (docs decision)

**Prompt:** "Can you update my decision in Agents.MD. This application no longer
limited to local LLMs, due to limited capability of local LLM. Also, please
write down the decision in ADRs."

### Decision

Local-only inference is no longer a requirement. The app may use remote LLM
providers in addition to on-device `flutter_gemma` models, because the small
local models are too limited for the desired interpretation quality. Local
inference remains supported as an option. Privacy and key-handling implications
are documented as consequences/follow-ups.

### Files changed

- `AGENTS.md`
  - Tech-stack table: LLM runtime/model rows now allow on-device **and/or**
    remote providers.
  - Section 1 "Key constraint": replaced the local-only/no-external-API
    statement with the new provider-agnostic constraint, including the privacy
    consequence and a link to ADR 0001.
  - Section 4 Services: noted `LlmService` may be local or remote.
  - Section 7 Key Patterns: `LlmService`, model startup and `.litertlm` notes
    clarified for on-device vs remote.
  - New section 9 "Architecture Decisions (ADRs)" linking `docs/adr/`.
- `docs/adr/README.md` (new) — ADR index and format.
- `docs/adr/0001-remote-llm-support.md` (new) — the decision, context,
  consequences, follow-ups and alternatives.

### Notes / follow-ups

This change is documentation only; no code was touched. `spec.md`, `README.md`
and `app/test/privacy_test.dart` still asserted local-only / no-external-network
behaviour at that point; they were aligned in the follow-up task below.

## Task: Align privacy docs/copy/tests with the remote-LLM decision

Follow-up to the above. Scanned every tracked file for privacy / offline /
local-only / no-network wording and updated the ones that contradicted the new
decision.

### Privacy scan results

- `README.md` — tagline, features, flow diagram and Privacy section rewritten
  (on-device **or** remote; prompt is sent to a configured provider; local
  SQLite storage; no telemetry beyond provider traffic).
- `spec.md` — user story, architecture, project-plan privacy item, on-device
  runtime note and privacy-test description updated.
- `app/lib/l10n/app_localizations.dart` (in-app privacy copy) —
  `privacySubtitle`, `privacyNoticeBody`, `modelsOffline`, `oneTimeDownload`
  and `internetNotice` updated (EN + zh-TC) to describe local **and** remote
  inference and the data sent to a remote provider.
- `app/test/model_selection_screen_test.dart` — updated the expected
  `modelsOffline` string.
- `app/test/privacy_test.dart` — re-scoped from "no network at all" to "no
  **unintended** network": static allowlist now permits the LLM services
  (`llm_service.dart` + planned `remote_llm_service.dart`); the runtime guard is
  explicitly limited to the on-device consultation flow (remote-provider mode is
  expected to use the network and is not covered).
- `logs/llm_research.md` — **left unchanged**; it is a historical research log
  of the original local-only exploration, not a living policy document.
- No standalone privacy policy / store-listing document exists in the repo.

### Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (229 pass)

## Task: LLM backend abstraction (#83)

**Parent:** #82 (Firebase AI Logic). First slice: a pluggable backend seam,
with no behavior change and no Firebase dependency.

### Changes

- New `app/lib/services/llm_prompts.dart` — a pluggable `LlmPromptStrategy`
  (prompt building, response cleaning, memory parsing) plus
  `DefaultLlmPromptStrategy` for the on-device model. `LocalGemmaBackend`
  accepts an injected strategy so a remote backend (Gemini) can use its own
  prompts/structured output. The legacy static helpers remain for compatibility.
- New `app/lib/services/llm_backend.dart` — `LlmBackend` contract + the moved
  `MemoryExtraction` model.
- New `app/lib/services/local_gemma_backend.dart` — the existing
  `flutter_gemma` implementation (model download/path/init, one-shot
  explanation, memory extraction, cleanup) behind `LlmBackend`.
- `app/lib/services/llm_service.dart` — now a thin facade delegating to the
  active backend (local by default) and re-exporting `LlmBackend` /
  `MemoryExtraction` / `LlmPromptStrategy`; the local-model management API is
  preserved for the screens.
- `app/test/llm_service_test.dart` — added backend-delegation and
  prompt-strategy injection tests.
- `app/test/privacy_test.dart` — allow `local_gemma_backend.dart` in the
  network allowlist (the model download moved there).

### Notes

- No behavior change: the default active backend is `LocalGemmaBackend` with
  `DefaultLlmPromptStrategy`.
- `FakeLlmService` continues to extend `LlmService`.
- The docs/privacy alignment from the previous task is still in the working
  tree (not part of this commit).

### Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (232 pass)
