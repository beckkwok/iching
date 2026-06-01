# Change Log - 2026-06-01

## Chat Interface Prototype

### Thinking
User requested a chat interface prototype showing conversation between user and system (server). The current app is a default Flutter counter template. I built:

1. A `ChatMessage` model to represent messages (user vs system)
2. A `ChatScreen` widget with:
   - Scrollable message list with styled bubbles
   - Text input field with send button
   - Welcome message on load
   - Placeholder system responses (will be replaced with real Gua engine + LLM later)
   - Auto-scroll to bottom on new messages
3. Updated `main.dart` to use the `ChatScreen` as home
4. Updated tests to cover:
   - Welcome message display
   - User typing and sending
   - System response after user message
   - Send button interaction

## SQLite Data Layer

### Thinking
User requested the SQLite persistence layer per the spec's data model (Conversation, Chat, Gua).

Design decisions:
- Used `sqflite` + `sqflite_common_ffi` (FFI for unit testing without emulator)
- In-memory database per test via `inMemoryDatabasePath` + cleanup in setUp/tearDown
- `DatabaseService` accepts optional `databasePath` for test injection
- `ChatMessage` updated with `dbId`, `conversationId`, `toMap()`, `fromDbMap()`
- `Conversation` and `Gua` models with `toMap()/fromMap()` and `copyWith()`
- Manual cascade delete on messages (some SQLite builds don't enforce FK cascades)
- Foreign keys defined for referential integrity

### Files Changed
- `app/pubspec.yaml` - ADDED: sqflite, path, sqflite_common_ffi, sqlite3
- `app/lib/models/chat_message.dart` - EXTENDED: dbId, conversationId, serialization
- `app/lib/models/conversation.dart` - NEW: Conversation model
- `app/lib/models/gua.dart` - NEW: Gua model
- `app/lib/services/database_service.dart` - NEW: Full DB service with CRUD
- `app/test/database_service_test.dart` - NEW: 16 data layer tests
## Gua Seed Data (64 Hexagrams)

### Thinking
User modified spec.md and asked to populate the Gua table with data from the
Wikipedia page for the 64 hexagrams (周易六十四卦列表).

I fetched the Wikipedia page via the REST API and raw wikitext, extracted:
- All 64 hexagram names (Chinese characters)
- All 64 common names (通稱 e.g. 乾爲天, 水雷屯)
- Descriptions/meanings for each hexagram

Created a comprehensive Dart data file with all 64 entries, each containing:
- guaCode (1–64), guaName (Chinese + pinyin), guaContent (trigram composition
  and classical meaning), guaSummary (reflection-oriented English prompt),
  source ('classical')

Also created a GuaSeeder service that:
- Checks if Gua table already has records (idempotent)
- Inserts all 64 hexagrams from HexagramData
- Returns count of inserted rows

### Files Changed
- `app/lib/data/hexagram_data.dart` - NEW: All 64 hexagrams with name, content, summary
- `app/lib/services/gua_seeder.dart` - NEW: Seeds Gua table on first launch
- `app/test/gua_seeder_test.dart` - NEW: 6 tests (insert, idempotent, validation, gaps, sources, retrieval)
- `logs/change_log_2026_06_01.md` - UPDATED: This entry

### Spec Changes Detected
- New detail: auto-create conversation title from date-time on first message
- Messages stored with conversationId
- Conversation list via burger menu (top-left)
- Click on conversation shows preview
- New implementation task: "build list of conversation component" and "Link UI with persistence"
