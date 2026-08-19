# Change Log — 2026-07-10

## Prompt
Create integration tests for:
1. Question form → cast result → hexagram detail.
2. Browse hexagram.

## Thinking

### Design
Added `integration_test/cast_and_browse_test.dart` with two end-to-end tests
that run on a real Windows app build:

1. **question → cast result → hexagram detail**
   - Pump `QuestionFormScreen` with a seeded in-memory DB.
   - Select "Career Achievement", enter a question, submit.
   - Assert `CastResultScreen` renders (卦象 + 爻象 + "Tap for details").
   - Tap the tappable 卦象 card → `HexagramDetailScreen` renders (卦辭 section).
   - Tap the close (X) button → back to `CastResultScreen`.

2. **browse hexagram → detail**
   - Pump `HexagramBrowserScreen` with the seeded DB.
   - Assert the grid renders.
   - Tap the 乾為天 card → `HexagramDetailScreen`.
   - Close → back to the browser.

Both tests reuse the real `GuaSeeder` with the asset JSON files, so the data
is the actual seeded hexagrams (卦名 from 卦名 field, e.g. 乾為天).

## Files Changed

### Created
- `app/integration_test/cast_and_browse_test.dart` — 2 integration tests

## Test Results
- Integration tests (cast_and_browse): 2/2 passed on Windows
- Unit tests: 88/88 passed
