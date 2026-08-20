# Change Log 2026-08-20

## Task: Clean up llm_service.dart (one-shot explanation flow)

User review of `lib/services/llm_service.dart` surfaced stale/dead code from the
chat era. All four issues fixed in one commit.

### Changes

1. **Stale `_systemPrompt` default updated** — the default prompt still told the
   model it had access to the `generate_gua` function and to wrap responses in
   JSON, both long gone. Rewrote it for the one-shot tool-free flow. The
   `systemPrompt` field itself is kept — it is live, edited by the Settings
   prompt editor and injected as the `systemInstruction` when opening the chat.

2. **Removed dead `_fallbackContext`** — was only the `??` fallback when
   `guaGenerator` was null, but `model_selection_screen.dart:240-242` always
   wires it before explanations run. `generateExplanation` now uses
   `_guaGenerator!.formatContext(result)` directly.

3. **Confirmed settings prompt wiring** — the explanation prompt has two parts:
   the customizable system prompt (Settings menu → `systemPrompt` →
   `systemInstruction` in `openExplanationChat`) and the hardcoded user-message
   template (question + hexagram + language). Both are intentional; nothing to
   change.

4. **Dropped JSON response format to save tokens** — removed the
   "Wrap your final response in JSON" instruction from both the user prompt and
   `_systemPrompt`; removed `_extractJsonMessage` and the now-unused
   `dart:convert` import; return trimmed text directly.

### Verification
- `flutter analyze` — no new issues (only 2 pre-existing warnings)
- `flutter test` — 88 tests pass
- `flutter test -d windows integration_test/cast_and_browse_test.dart` — 2 tests pass