# Change Log — 2026-06-04

## Summary
Multiple model switches and fixes for Qwen3 thinking mode issue. Added context-length fallback with LLM summarization.

## Changes

### `app/lib/services/llm_service.dart`

1. **Temperature lowered** from 0.9 → 0.8 for more consistent responses.

2. **Empty response retry guard** — when the model returns only `<think>\n` with no actual content, sends a nudge and retries (up to 3 turns) instead of returning empty string.

3. **Model switches** (all reverted back to Qwen3 0.6B in the end):
   - Qwen3 0.6B → Qwen2.5 0.5B Instruct (thinking tags still present)
   - Qwen2.5 0.5B → Gemma 3 1B IT (needed HF token, `.litertlm` format)
   - Gemma 3 1B → Qwen3 0.6B (final, reverted)

4. **`/no_think` appended to tool call responses** — Qwen3's thinking mode re-activates after tool call results. The `chat.dart` library only appends `/no_think` to `isUser == true` messages, but tool call responses have `isUser == false`. We now append `\n/no_think` to the tool call context text sent back to the model.

5. **Debug prints added** to `downloadModel()` and `_registerAndLoad()` to show the absolute model file path.

6. **Context-length fallback with LLM summarization** — when retries are exhausted (model stops responding due to long context):
   - Step 1: Close chat, open fresh → send full meaningful conversation to LLM with a summarization prompt (~250 words)
   - Step 2: Close chat, open fresh → feed the summary as context + re-send original user query
   - Filters out retry nudges (toolCall type), thinking-only messages, and empty responses from the history before summarizing

### `app/pubspec.lock`
Auto-updated by dependency resolution (no meaningful change).

## Files Changed
- `app/lib/services/llm_service.dart`
- `app/pubspec.lock`
