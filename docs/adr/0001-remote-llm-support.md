# ADR 0001: Allow remote LLM providers alongside on-device models

- **Status:** Accepted
- **Date:** 2026-10-27
- **Related:** [#5](https://github.com/beckkwok/iching/issues/5) (progressive interpretation)

## Context

The app was originally designed around on-device inference only, using
`flutter_gemma` with small Gemma / Qwen3 0.6B-class models. The local-only
constraint came with strong privacy wording: no internet after model download,
no external API calls.

In practice, the on-device models are too limited for the interpretation quality
we want. A 0.6B-class model struggles with the richer I-Ching context (爻辭,
變卦, multi-step interpretation) and CPU inference is slow — the current
explanation call caps output at 512 tokens with a 120 s timeout
(`app/lib/services/llm_service.dart`). Local-only also rules out the progressive
flow planned in #5.

## Decision

On-device inference is no longer a hard constraint. The app **may** use remote
LLM providers in addition to (or instead of) on-device models. Local inference
remains supported as an option, but it is not required. Which provider is used,
how it is configured, and whether local/remote can be selected by the user are
implementation follow-ups.

### Firebase AI Logic implementation (2026-11-05)

- **Android** is the remote edition: `firebase_ai` (Gemini Developer API, free
  tier) + `firebase_app_check`, with a first-run consent screen
  (`FirebaseConsentScreen`).
- **Windows/Linux** are the local edition (`flutter_gemma`); `firebase_ai` has
  no Windows/Linux support.
- Config comes from a git-ignored `app/firebase.local.json` via
  `--dart-define-from-file`; `google-services.json` and committed API keys are
  **not** used.
- **App Check is mandatory** for Firebase AI Logic (enforcement began
  2026-11-02): debug provider in development (a fixed token can be pinned),
  Play Integrity in release.
- Cost controls: default to a free-tier Flash-Lite model,
  `maxOutputTokens: 512`, and budget alerts/spend caps in Google Cloud.
- Real provider calls are covered by a **manual smoke test**
  (`integration_test/manual/`); unit tests inject a mock
  `FirebaseContentGenerator`.

## Consequences

**Positive**

- Higher-capability models, so noticeably better and richer interpretations.
- Multi-step / progressive interpretation (#5) becomes practical.
- Faster responses on low-end devices, and no 0.6B model download required.

**Negative / risks**

- Remote inference requires internet access; offline use is no longer guaranteed.
- The prompt (the user's question + hexagram context) is sent to the configured
  provider, so the privacy notice and consent flow must reflect that.
- Provider credentials/API keys must be stored securely and never committed.
- Need network/provider error handling (timeouts, retries, rate limits).
- Possible cost/quota implications if a paid provider is used.
- Tests must not make real network calls; keep provider calls behind an interface
  so they can be faked.

## Follow-ups

Done:

- ✅ Pluggable `LlmBackend` with `LocalGemmaBackend` + `FirebaseAiBackend`
  (#83/#85).
- ✅ Android remote / Windows-local selection + first-run consent (#86).
- ✅ Secret-free config via a git-ignored `app/firebase.local.json` and
  `--dart-define-from-file` (#97).
- ✅ Docs/privacy copy and the "no unintended network" guard (#87).

Still open:

- Restrict the Google API key to the Android app + the Firebase/Gemini APIs
  (currently Android-app restriction only).
- Play signing + Play Integrity for release (debug cert/token used today).
- Configure macOS/iOS/web Firebase apps if those platforms get remote inference.
- Set Cloud budget alerts/spend caps (documented, not yet configured).

## Alternatives considered

- **Keep local-only.** Rejected: local model capability is insufficient for the
  desired interpretation quality.
- **Bundle a larger local model.** Rejected for app-size and device-memory
  constraints (and still slower than a remote provider).

## Supersedes

The local-only constraint previously stated in `AGENTS.md` (section 1, "All LLM
inference runs locally on-device") and `spec.md` (offline privacy requirements).
