# Change Log — 2026-07-11

## Prompt (user's thoughts)
The chat-based design is not usable: the local LLM's limited context cannot
sustain more than ~5 rounds, which violates the original "chat like a person"
idea. Revise the flow to be less human but still use the LLM effectively:
form-based question → generate hexagram → use the hexagram context + user
question to provide an explanation. This drastically reduces token burden.
Eventually the chat screen flow will be removed if this works.

## Thinking

### Problem
Multi-round chat accumulates history, blowing past the on-device model's
context window quickly. The fix is a **single-shot consultation**: capture the
question once via the form, cast a hexagram, and make exactly one LLM call
that combines the hexagram content with the question.

### Design
1. **`LlmService.generateExplanation()`** — a one-shot call:
   - Requires an open chat (no function calling, no multi-turn history).
   - Builds one prompt: user question + category + hexagram context
     (卦辭/彖傳/大象傳/象徵總結 via `formatContext`, with a `_fallbackContext`
     when no GuaGenerator is wired).
   - Sends one query, strips thinking tags, extracts JSON message, returns.
   - Falls back to a friendly message on timeout/empty.
2. **`FakeLlmService.generateExplanation()`** — deterministic override for
   tests.
3. **`ExplanationScreen`** — shows the question card, hexagram card, and the
   解讀 (explanation) card. Loading spinner while the LLM runs; placeholder
   when no LLM is available; error state on failure.
4. **`CastResultScreen`** — now accepts `question`, `questionTypeLabel`, and
   `llmService`; shows a "Get Explanation" button (only when a question is
   present) that pushes `ExplanationScreen`.
5. **`QuestionFormScreen._submit`** — passes question, type label, and
   llmService through to `CastResultScreen`.

## Files Changed

### Created
- `app/lib/screens/explanation_screen.dart` — one-shot explanation view
- `app/test/explanation_screen_test.dart` — LLM + no-LLM tests

### Modified
- `app/lib/services/llm_service.dart` — `generateExplanation()` +
  `_fallbackContext()`
- `app/lib/services/fake_llm_service.dart` — `generateExplanation()` override
- `app/lib/screens/cast_result_screen.dart` — question/type/llm params +
  "Get Explanation" button
- `app/lib/screens/question_form_screen.dart` — pass question/type/llm to cast
- `app/test/cast_result_screen_test.dart` — explanation button tests
- `app/integration_test/cast_and_browse_test.dart` — extended flow to include
  explanation step
- `AGENTS.md` — updated gua schema + consultation flow pattern

## Test Results
- Unit tests: 92/92 passed
- Integration tests: cast_and_browse 2/2, all_tests 10/10 passed
