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
5. Implementation tasks
    - scaffold app project
    - implement SQLite persistence layer
    - build conversation UI components
    - build list of coversation component.
    - Link conversation UI with persistance layer
    - integrate offline Gemma LLM or local model runtime
        - research if there is any flutter support for local llm. or install https://pub.dev/packages/flutter_gemma plugin to connect to local llm if no better choice
        - default a model if necessary
        - try to send user prompt to the model
        - get the user response and return and server response
    - customize server prompt design
    - add privacy / local-only enforcement checks
    - build history and settings screens

6. Testing, deployment, and documentation
    - unit tests for gua generator and data model
    - integration tests for conversation flow and history
    - privacy validation to ensure no network calls
    - Android packaging and build verification
    - user documentation for usage and privacy assurances