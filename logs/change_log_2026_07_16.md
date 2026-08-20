# Change Log 2026-07-16

## Task: Remove chat flow — replace with form-based consultation

The multi-turn chat UI was unusable with the on-device local LLM because context
rapidly exceeds the model's context window. Per user decision, the chat flow is
removed entirely and replaced with the form-based, one-shot explanation flow.

### Step 0 — `main dd5b34f`
`feat: add settings menu, editable system prompt, and one-shot explanation flow`

- Add settings menu on question form screen
- Add back button on cast result screen
- Add PromptEditorScreen for editing the custom system prompt
- Revamp LLM to one-shot/tool-free explanation call
- Add prompt print in explanation

### Step 1
`refactor: remove chat screens, models, and chat integration tests`

- Delete `chat_screen.dart`, `conversation_detail_screen.dart`, `gua_card.dart`
- Delete chat-only integration tests (chat_flow, chat_with_gua, navigation, persistence, all_tests)
- `model_selection_screen.dart`: preload with `openExplanationChat()` (tool-free),
  rename proceed flow to `_proceed()`, drop chat wording
- Remove GuaCard navigation test from hexagram detail tests

### Step 2 — `main 948eda8`
`refactor: remove chat methods from LlmService and FakeLlmService`

- Remove `sendMessage`, `_compressContext`, `_tools` (generate_gua), `openChat`,
  `consumeGeneratedGua`, `lastGeneratedGua`, `_guaGenerated`, `resetGuaGuard`
- Move `_responseTimeout` to explanation section
- Rewrite `fake_llm_service.dart` (only `explanationResponse` + `generateExplanation` override)

### Step 3 — `main fb00c99`
`refactor: drop conversation/message persistence from DatabaseService`

- Remove `conversations` and `chat_messages` tables (DB v5 migration)
- Remove conversation/message CRUD and the `chat_message`/`conversation` models
- Remove `GuaGenerator.associateWithConversation` (dead code)
- Rewrite `database_service_test.dart` to Gua + Settings only
- Repurpose `tools/db_inspector.dart` to dump gua + settings
- Add v5 migration test verifying tables are dropped

### Step 4 — Docs
`docs: update README, AGENTS, spec for form-based flow`

- README: features, data flow, DB schema, tech stack, fix "Run the appNice," typo
- AGENTS.md: project tree, DB schema (gua + settings), key patterns (one-shot flow), test command
- spec.md: rewritten for form-based consultation flow

### Notes
- `Gua` model `id` field and the `gua` DB table are intentionally KEPT for now
  (deferred to a separate task: load hexagrams directly from JSON assets).
- Surviving integration test `cast_and_browse_test.dart` kept as-is for now;
  will be adapted to JSON-direct flow when the gua table is removed.