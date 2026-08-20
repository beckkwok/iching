# Change Log — 2026-07-14

## Prompt
1. In `cast_result_screen.dart`, add a back button to return to
   `question_form_screen.dart`.
2. In `settings_screen.dart`, allow the user to view and modify the system
   prompt.

## Thinking

### 1. Back button
The question form previously used `pushReplacement` to go to the cast result,
which removed the form from the stack. Changed it to `push` so the form stays
below, and added an explicit back (arrow) button in `CastResultScreen`'s AppBar
that pops back to the question form.

### 2. Editable system prompt
- `LlmService.systemPrompt` is now a mutable field (defaults to the built-in
  `_systemPrompt` constant) and `openChat()` uses it. Settings key
  `system_prompt` persists a custom value.
- New `PromptEditorScreen`: loads the current prompt (saved custom value, else
  the LLM default), lets the user edit, and on Save persists it to the
  settings table and applies it to the live `LlmService`. A Reset button
  restores the LLM default text.
- `SettingsScreen`'s "System Prompt" tile now opens the editor.
- `ModelSelectionScreen._applySavedPrompt()` loads a saved prompt before each
  `openChat()` so the customization survives app restarts.

## Files Changed

### Created
- `app/lib/screens/prompt_editor_screen.dart`
- `app/test/prompt_editor_screen_test.dart`

### Modified
- `app/lib/screens/question_form_screen.dart` — `push` instead of
  `pushReplacement`
- `app/lib/screens/cast_result_screen.dart` — AppBar back button
- `app/lib/services/llm_service.dart` — mutable `systemPrompt` + settings key
- `app/lib/screens/settings_screen.dart` — wire System Prompt tile to editor
- `app/lib/screens/model_selection_screen.dart` — `_applySavedPrompt()` before
  `openChat()`
- `app/test/cast_result_screen_test.dart` — back button test

## Test Results
- Unit tests: 103/103 passed
- Integration tests: cast_and_browse 2/2, all_tests 10/10 passed
