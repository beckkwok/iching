# I-Ching specification

**Important: Before committing any change, ensure ALL tests pass:**
```bash
cd app
flutter test                    # Unit + widget tests
flutter test -d windows integration_test/cast_and_browse_test.dart  # Integration tests (Windows desktop)
```

Objective
=========
This application is to build a consultancy service to the one who is in the cross road, provide some emotional support to the user. THe discussion should be encourage and open, targe to make user happy

User Story
----------
1. A form-based UI is displayed with:
    - A question category (Career Achievement, Intellectual and moral cultivation, Timing, Attitude)
    - A text box to allow user to type the things that bother him
    - A button to submit the query
2. The system casts a 'gua' (六爻, three-coin method) and shows the hexagram (卦象) with per-line yao types.
3. The user taps "Get Explanation" and the local LLM generates a reflection/explanation combining the hexagram context, the question, and the language preference (one-shot, no chat history, stays within on-device context limits).

Architecture Overview
---------------------
1. The project build as android application. Flutter is the framework.
2. The system uses Gemma-compatible local models (via `flutter_gemma`). The whole process does not call the internet to protect user privacy (network only used to download the model at first run).
3. The following will be stored:
    - Gua content — as JSON asset files (`assets/hexagrams/gua_<n>.json`) and seeded into the `gua` SQLite table
    - Settings (language preference, custom system prompt, selected model) — `settings` SQLite table

UI function
-----------
- Question form → cast result → explanation flow
- Hexagram browser + detail screens (all 64 hexagrams)

System function
---------------
- Program to generate gua (64), via three-coin casting (`GuaGenerator.generateRandom()`)

Project Plan
-------------
1. Define project scope
    - Confirm target platform and framework (Android app, Flutter)
    - Define offline privacy requirements (no internet access, local model only)
    - Clarify main user flow: question form -> cast gua -> one-shot LLM explanation
2. Design data model
    - Gua
        - Gua ID
        - Gua Code (1-64, 卦序)
        - Gua Name (e.g. 乾為天)
        - Gua Content (full hexagram JSON, see HexagramContent)
    - Settings
        - Key (language, system_prompt, selected_model_key)
        - Value
3. Define views
    - Question form screen
        - question category selector, question text input, submit button
    - Cast result screen
        - hexagram 卦象 + per-line yao types (老陰/少陽/少陰/老陽)
        - "Get Explanation" button → LLM
    - Explanation screen
        - shows the LLM-generated reflection
    - Hexagram browser + detail screens
        - grid of all 64 hexagrams; detail shows 卦辭, 彖傳, 大象傳, 爻辭, 象徵意義, 不同人解讀
    - Model selection screen
        - choose + download a model at first run (persisted in settings)
    - Settings interface
        - language preference, editable system prompt (PromptEditorScreen)
4. Define business logic
    - Gua casting
        - support random generation via three-coin method
        - produce one of 64 gua codes via trigram mapping (TrigramHexagramData)
    - Gua retrieval
        - load gua content from store (JSON assets / gua table)
    - Explanation
        - one-shot LLM call: hexagram context + question + language preference, no function calling, no history
5. Implementation tasks ✅ Completed
    - scaffold app project
        - Flutter project with proper folder structure and all dependencies
    - implement SQLite persistence layer
        - database_service.dart (gua + settings tables, migrations to v5)
    - Gua seeding at startup via GuaSeeder.seedIfNeeded() from assets/hexagrams JSON
    - integrate offline Gemma-compatible local model runtime
        - flutter_gemma plugin integrated
        - Model catalog (6 models) + download on first run
        - openExplanationChat() tool-free session
    - customize server prompt design
        - I-Ching consultant system prompt with reflection guidelines
    - build gua generator
        - GuaGenerator class with generateRandom() and GeneratorMethod enum
        - formatContext() with different headers per method
    - build gua parser / trigram mapping
        - TrigramHexagramData resolves cast lines to hexagram
    - build hexagram browser and detail screens
    - build form-based consultation flow
        - QuestionFormScreen → CastResultScreen → ExplanationScreen

5b. Implementation tasks 🔲 Remaining
    - Strategy pattern for GuaGenerator (GuaGeneratorStrategy interface)
    - Display independent image related to the gua
    - Enrich the gua content
    - Load hexagrams directly from JSON assets (remove the `gua` DB table and `Gua.id`)
    - add privacy / local-only enforcement checks
    - Android packaging and build verification
    - user documentation for usage and privacy assurances

6. Testing, deployment, and documentation ✅ Completed
    - unit tests for gua generator (gua_generator_test.dart)
    - unit tests for data models / DB (database_service_test.dart, hexagram_content_test.dart)
    - unit tests for gua seeder (gua_seeder_test.dart)
    - unit tests for trigram mapping (trigram_hexagram_data_test.dart)
    - widget tests for UI screens (question_form, cast_result, explanation, hexagram_browser, hexagram_detail, settings, prompt_editor)
    - integration test cast_and_browse_test.dart — cast flow + hexagram browser
    - FakeLlmService for deterministic LLM responses in tests
    - migration test (migration_v4_test.dart) verifies schema migrations

6b. Testing, deployment, and documentation 🔲 Remaining
    - privacy validation to ensure no network calls
    - Android packaging and build verification
    - user documentation for usage and privacy assurances
