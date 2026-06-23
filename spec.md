# I-Ching specification

**Important: Before committing any change, ensure ALL tests pass:**
```bash
cd app
flutter test                    # Unit + widget tests
flutter test integration_test/  # Integration tests (Windows desktop)
```

Objective
=========
This application is to build a consultancy service to the one who is in the cross road, provide some emotional support to the user. THe discussion should be encourage and open, targe to make user happy

User Story
----------
1. A UI will be displayed with:
    - A text box to allow user to type the things that bother him
    - A button to submit the query
2. If the gua does not provided in the prompt, The system then generate the 'gua' for the user, which it will retrieve the corresponding information, then the system should briefly describe the content of the 'gua', but should not tell the good or bad, but to encourage user for more information, and how he feel about the 'gua', to reflect its thought.
3. The process should be continued. System should store the conversation.

Architecture Overview
----------------------
1. The project build as andriod application. hybrid framework like react-native is suggested
2. The system uses Gemma as LLM model. The whole process should not called internet to protect user privacy
3. The following will be stored in sqlite db:
    - Gua content
    - conversation detail

UI function
-----------
- Main conversation interface
- Menu function to list the past conversation history

System function
---------------
- Program to generate gua (64)

Project Plan
-------------
1. Define project scope
    - Confirm target platform and framework (Android app, React Native / hybrid)
    - Define offline privacy requirements (no internet access, local model only)
    - Clarify main user flow: user input -> optional gua parse -> generate/retrieve gua -> encourage reflection
2. Design data model
    - Conversation
        - Conversation ID
        - Conversation Title
        - Created At
        - Updated At
        - Last Gua ID
    - Chat
        - Chat ID
        - Conversation ID
        - Sender (User / System)
        - Message
        - Timestamp
    - Gua
        - Gua ID
        - Gua Code (Non unique)
        - Gua Name
        - Gua Content
        - Gua Summary / Reflection Hint
        - Source / Generator Type
3. Define views
    - Main conversation interface
        - text input field
        - submit button
        - scrollable chat history
        - when user submit message, if the convesation has not been initialised, system will create a conversation title (date-time)
        - both user message and system response will stored in the chat, with the same conversation id
    - Past conversation lists
        - Activated from the burger menu (with history icon) from to top-left corner
        - list of conversation title displayed
        - when user click on the conversation title, preview convesation will be displayed
    - Conversation detail view
        - Displayed when user select specific conversation from the conversation list
        - full chat log
        - gua details when selected
    - Settings interface
        - privacy notice
        - local storage management
4. Define business logic
    - Input handling
        - detect explicit gua in user prompt
        - otherwise request generated gua
    - Gua generation
        - support random generation
        - support multiple generator methods
        - produce one of 64 gua codes
    - Gua retrieval
        - load local gua content from store
        - summarize without judging good/bad
        - frame response as encouragement and reflection
    - Conversation management
        - persist each chat message
        - associate system response with gua where applicable
        - support continuing conversations later
5. Implementation tasks ✅ Completed
    - scaffold app project
        - Flutter project with proper folder structure and all dependencies
    - implement SQLite persistence layer
        - database_service.dart with full CRUD for conversations, messages, gua
    - build conversation UI components
        - chat_screen.dart with message bubbles, text input, buttons
    - build list of conversation component
        - History drawer with titles, timestamps, active indicator
    - Link conversation UI with persistence layer
        - Messages persisted on send and response
        - Conversation auto-title with date-time
    - integrate offline Gemma LLM or local model runtime
        - flutter_gemma plugin integrated
        - Model download from HuggingFace (Qwen3 0.6B)
        - Send user prompt and receive response
        - Function calling support (generate_gua tool)
        - /no_think suppression for Qwen3 thinking mode
        - Empty response retry guard
        - Proactive context compression with LLM summarization
        - Trailing text capture after function call JSON
    - customize server prompt design
        - I-Ching consultant system prompt with reflection guidelines
    - Build gua generator
        - GuaGenerator class with generateRandom() and findInText()
        - Multiple GeneratorMethod (userRequested, randomCast, automatic)
        - formatContext() with different headers per method
    - LLM integration with gua generator via function calling
        - LLM calls generate_gua -> GuaGenerator generates -> context fed back
    - Build gua parser (findInText)
        - Detects gua by Chinese name, pinyin, or number in user text
    - build history screen
        - conversation_detail_screen.dart for full chat log
    - gua as separate response
        - GenerationResult wraps gua + method, formatted as tool call context

5b. Implementation tasks 🔲 Remaining
    - Strategy pattern for GuaGenerator (GuaGeneratorStrategy interface)
        - setParam(), generate(), prompt() per strategy
        - SimpleGuaGeneratorStrategy: random 1-64, specific prompt
    - Build gua parser for user-provided gua -> return full gua result
    - bug fix, model location
    - LLM response change to JSON format for chat screen
    - Display independent image related to the gua
    - add privacy / local-only enforcement checks
    - Enrich the gua content.
    - allow user to delete the chat history. In the chat history page, user hold the chat history item, then system prompt the confirmation button to user whether he want to delete the chat history.
    - build settings screen, on the main chat screen, there is a burger menu on the right, when user click the burger menu, the following setting displayed:
        - privacy notice
        - model path
        - model selection
        - prompt settings
        - local storage management

6. Testing, deployment, and documentation ✅ Completed
    - unit tests for gua generator (gua_generator_test.dart)
    - unit tests for data model (database_service_test.dart)
    - unit tests for gua seeder (gua_seeder_test.dart)
    - widget test for UI flow (widget_test.dart)
    - integration tests for chat flow, Gua card, navigation, persistence
        - chat_flow_test.dart — welcome message, send/receive, button state, multi-message
        - chat_with_gua_test.dart — GuaCard rendering, single-Gua guard
        - navigation_test.dart — history drawer, settings screen, privacy dialog, back navigation
        - persistence_test.dart — messages survive DB reload, appended after reload
    - FakeLlmService for deterministic LLM responses in integration tests

6b. Testing, deployment, and documentation 🔲 Remaining
    - privacy validation to ensure no network calls
    - Android packaging and build verification
    - user documentation for usage and privacy assurances