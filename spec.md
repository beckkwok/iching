# I-Ching specification

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
    - Past conversation list
        - conversation title
        - preview text or last message
        - open existing conversation
    - Conversation detail view
        - full chat log
        - gua details when selected
    - Settings interface
        - privacy notice
        - local storage management
        - generator options if multiple supported
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
5. Implementation tasks
    - scaffold app project
    - implement SQLite persistence layer
    - build conversation UI components
    - build history and settings screens
    - integrate offline Gemma LLM or local model runtime
    - add privacy / local-only enforcement checks
6. Testing, deployment, and documentation
    - unit tests for gua generator and data model
    - integration tests for conversation flow and history
    - privacy validation to ensure no network calls
    - Android packaging and build verification
    - user documentation for usage and privacy assurances