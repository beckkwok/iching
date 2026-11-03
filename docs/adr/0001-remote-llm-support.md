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

Done with this decision:

- ✅ Updated `spec.md`, `README.md` and the in-app privacy copy (EN + zh-TC) to
  describe on-device **and** remote inference.
- ✅ Re-scoped `app/test/privacy_test.dart` from "no network at all" to "no
  **unintended** network": the static allowlist now permits the LLM services
  (`llm_service.dart` + planned `remote_llm_service.dart`), and the runtime guard
  is explicitly limited to the on-device flow.

Still open:

- Abstract the LLM behind the existing `LlmService` interface so on-device and
  remote backends are interchangeable.
- Design provider selection/configuration and secure key storage.
- Add a clear privacy notice/consent before sending data to a remote provider.

## Alternatives considered

- **Keep local-only.** Rejected: local model capability is insufficient for the
  desired interpretation quality.
- **Bundle a larger local model.** Rejected for app-size and device-memory
  constraints (and still slower than a remote provider).

## Supersedes

The local-only constraint previously stated in `AGENTS.md` (section 1, "All LLM
inference runs locally on-device") and `spec.md` (offline privacy requirements).
