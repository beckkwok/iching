# Change Log — 2026-07-15

## Prompt
The LLM call for explanations fails: the model detects a `generate_gua` tool
call because the explanation reuses the function-calling chat. The app is no
longer chat-based, so revamp `llm_service`. Also print the explanation prompt
so the developer can verify it includes: hexagram info, the user's question,
and the language preference.

## Thinking

### Root cause
`generateExplanation` reused the chat opened by `openChat()`, which has
`supportsFunctionCalls: true` and the `generate_gua` tool. The model tried to
call the tool instead of answering directly.

### Design
1. **`openExplanationChat()`** — a new session with function calling disabled
   and no tools, so the model answers directly. Uses a lower temperature
   (0.7) for a more measured explanation.
2. **`generateExplanation`** is now self-contained: it opens its own
   tool-free session before sending the one-shot prompt (no longer requires a
   prior `openChat()`).
3. **Prompt inspection** — the full prompt is printed to the console
   (prefixed `📝 Explanation prompt:`) so the developer can confirm it
   contains the hexagram context, the user's question + category, and the
   language instruction.

### Prompt shape (verified by test)
```
The user asked: "<question>" (category: <label>)

The hexagram below was cast for them:
<formatContext: name, code, cast lines, line types, 卦辭/彖傳/大象傳/象徵總結>

Provide a compassionate I-Ching explanation ...
<Respond in English. | Respond in Traditional Chinese.>
Wrap your final response in JSON: {"message": "your response here"}.
```

## Files Changed

### Modified
- `app/lib/services/llm_service.dart` — `openExplanationChat()`, self-contained
  `generateExplanation`, prompt print

## Test Results
- Unit tests: 103/103 passed
- Integration tests: cast_and_browse 2/2, all_tests 10/10 passed
