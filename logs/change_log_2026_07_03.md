# Change Log — 2026-07-03

## Prompt
Change the first screen of the app from a chat interface to a question form:
- Ask what type of question the user wants to ask (e.g. Career, Family, Health).
- A text box to store the exact question.
- A button to submit the question.

## Thinking

### Design
1. **QuestionFormScreen** (`screens/question_form_screen.dart`) becomes the
   first screen after model setup. It shows:
   - A `QuestionType` dropdown with icons and validation.
   - A multi-line `TextFormField` for the exact question (required).
   - A "Submit Question" button that validates the form then navigates to the
     chat.
2. **Flow change**: `ModelSelectionScreen._proceedToChat` and `_skipDownload`
   now navigate to `QuestionFormScreen` instead of `ChatScreen`.
3. **ChatScreen** accepts optional `initialQuestion` + `questionType`. On load
   it auto-submits the initial question (post-frame) so the LLM responds
   immediately. The category is prefixed to the user message
   (e.g. `[Career Achievement] ...`) so the LLM has context.
4. Question type defined as an enum with `label` + `icon` so it can grow
   (values used for validation, display, and LLM framing).

### Revisions (same day)
1. **Question types** changed to: Career Achievement, Intellectual and moral
   cultivation, Timing, Attitude (per user).
2. **"Help me to generate hexagram" checkbox** added after the text box,
   defaulting to `true`. When unchecked, `ChatScreen` sets
   `llmService.guaGenerator = null` so the LLM cannot cast a hexagram.

## Files Changed

### Created
- `app/lib/screens/question_form_screen.dart` — the new first screen
- `app/test/question_form_screen_test.dart` — widget tests (renders fields,
  validation, navigation to chat, checkbox default + disable behavior)

### Modified
- `app/lib/screens/model_selection_screen.dart` — `_proceedToChat` and
  `_skipDownload` now go to `QuestionFormScreen`
- `app/lib/screens/chat_screen.dart` — `initialQuestion`, `questionType`,
  `generateHexagram` params, auto-submit on load, category framing of user
  message, disable gua generator when unchecked
- `AGENTS.md` — project structure updated (new screen, models, data files,
  assets/hexagrams, tests)

## Test Results
- Unit tests: 69/69 passed (incl. 5 form tests)
- Integration tests: 10/10 passed
