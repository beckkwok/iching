# Change Log — 2026-07-12

## Prompt
Add a language preference (EN / CN) in Settings, and inject the preference
into the LLM prompt so responses match the chosen language.

## Thinking

### Design
1. **LanguagePreference model** (`models/language_preference.dart`): enum
   `english('en')` / `chinese('cn')`, with `settingsKey = 'language'` and
   `fromCode()`.
2. **Settings screen**: new "Language" section with two `RadioListTile`s
   wrapped in a `RadioGroup` (the modern API; `groupValue`/`onChanged` on the
   tile are deprecated in Flutter 3.32+). Selecting an option persists the
   code via `DatabaseService.setSetting('language', 'en'|'cn')`.
3. **LlmService.generateExplanation**: new `language` param (default english);
   injects "Respond in English." / "Respond in Traditional Chinese." into the
   prompt.
4. **Flow threading**: QuestionFormScreen reads the stored preference before
   casting and passes it to CastResultScreen → ExplanationScreen →
   generateExplanation.

## Files Changed

### Created
- `app/lib/models/language_preference.dart`
- `app/test/language_preference_test.dart`
- `app/test/settings_screen_test.dart`

### Modified
- `app/lib/services/llm_service.dart` — `generateExplanation` language param
- `app/lib/services/fake_llm_service.dart` — language-aware override
- `app/lib/screens/settings_screen.dart` — Language selector (RadioGroup)
- `app/lib/screens/question_form_screen.dart` — read + pass language
- `app/lib/screens/cast_result_screen.dart` — language param, pass-through
- `app/lib/screens/explanation_screen.dart` — language param, pass-through
- `app/test/question_form_screen_test.dart` — async pump for extra DB read
- `app/integration_test/all_tests.dart` — ensureVisible before privacy tap

## Test Results
- Unit tests: 99/99 passed
- Integration tests: cast_and_browse 2/2, all_tests 10/10 passed
