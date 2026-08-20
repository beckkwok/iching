# Change Log — 2026-06-30

## Prompt
Revamp the `gua` table:
1. `gua_content` becomes a JSON object (no length limit).
2. Remove `summary` and `source` columns.
Save each hexagram as an individual JSON file; study the schema and build a parser. The user will provide the remaining 63 JSON files later.

## Thinking

### Schema study
The user supplied the JSON schema for hexagram 46 (地風升). Structure:
- Top-level: `卦名`, `卦序`, `卦象`, `卦辭`, `彖傳`, `大象傳`, `爻辭[]`, `象徵意義`, `不同人解讀[]`, `備註`
- `爻辭[]`: `爻位`, `爻辭`, `小象傳`
- `象徵意義`: `基本卦象{卦體,自然取象,說明}`, `主要象徵[{標題,內容}]`, `生活與占事常見象徵{}`, `總結`
- `不同人解讀[]`: `解讀者`, `卦辭解讀`, `爻辭解讀{爻位:解讀}`

### Design decisions
1. **Individual JSON files**: each hexagram stored as `assets/hexagrams/gua_<n>.json`. Only `gua_46.json` exists now; the user will add the rest. Registered `assets/hexagrams/` in pubspec.yaml.
2. **Parser**: new `HexagramContent` model (`models/hexagram_content.dart`) with typed nested classes `HexagramLine`, `SymbolicMeaning`, `BasicSymbol`, `MainSymbol`, `Interpretation`. Follows project conventions (`copyWith`, `toMap`, `fromMap`, `==`, `hashCode`, `toString`).
3. **Gua model**: removed `guaSummary` and `source`. `guaContent` holds the raw JSON string; lazy `content` getter parses it via `HexagramContent.fromJson`.
4. **DB migration v3**: `ALTER TABLE gua DROP COLUMN gua_summary/source` (SQLite 3.35+, bundled 3.53.2 supports it). Fallback rebuild for older SQLite.
5. **GuaSeeder**: loads `gua_<n>.json` files (default `rootBundle`, injectable `assetLoader` for tests). Only seeds missing codes, so partial file sets work incrementally. No longer uses `HexagramData`.
6. **Consumers**: `GuaCard` parses trigram lines from `guaSymbol` (卦象) and displays `guaSymbol`/`guaCi`/`象徵總結`; `GuaGenerator.formatContext` includes `卦辭`/`彖傳`/`大象傳`/`象徵總結`.
7. Deleted `lib/data/hexagram_data.dart` (superseded by JSON assets).

## Files Changed

### Created
- `app/assets/hexagrams/gua_46.json` — hexagram 46 (地風升) in the new JSON schema
- `app/lib/models/hexagram_content.dart` — typed parser for the schema
- `app/test/hexagram_content_test.dart` — parser round-trip + real asset parse test

### Modified
- `app/pubspec.yaml` — registered `assets/hexagrams/`
- `app/lib/models/gua.dart` — removed `guaSummary`/`source`, JSON-aware `guaContent` + lazy `content` getter
- `app/lib/services/database_service.dart` — DB version 3, drop gua columns in `_onUpgrade`
- `app/lib/services/gua_seeder.dart` — loads individual JSON files, injectable loader, seeds only missing
- `app/lib/services/gua_generator.dart` — `formatContext` uses parsed JSON fields
- `app/lib/widgets/gua_card.dart` — parses lines from 卦象, renders new fields
- `app/test/database_service_test.dart` — updated Gua fixtures + content parse test
- `app/test/gua_seeder_test.dart` — rewrote for JSON asset loader (64 fixtures, gaps, idempotency)
- `app/test/gua_generator_test.dart` — JSON fixture loader, updated formatContext assertions
- `app/integration_test/all_tests.dart` + `chat_with_gua_test.dart` — updated `_testGua`/`_findGuaByCode` to valid JSON

### Deleted
- `app/lib/data/hexagram_data.dart`

## Test Results
- Unit tests: 46/46 passed
- Integration tests (`all_tests.dart` + `chat_with_gua_test.dart`): 12/12 passed
