# Change Log — 2026-07-05

## Prompt
Add a browse button on the question form screen that lets the user browse all
hexagrams. Hexagrams are listed as cards in a 2-column grid; each card shows
卦序, 卦象, and 卦名. Tapping a card opens the HexagramDetailScreen.

## Thinking

### Design
1. **HexagramBrowserScreen** (`screens/hexagram_browser_screen.dart`):
   - Loads all seeded gua via `DatabaseService.getAllGua()`, sorted by guaCode
     (1..64).
   - Renders a `GridView.builder` with 2 columns.
   - Each card (`_HexagramTile`) shows 第N卦 (卦序), 卦象 symbol, and 卦名.
   - Tapping a card navigates to `HexagramDetailScreen`.
   - Handles null DB, load errors, and empty state.
2. **Browse button**: added an outlined "Browse Hexagrams" button on
   `QuestionFormScreen` below the submit button, navigating to the browser.

## Files Changed

### Created
- `app/lib/screens/hexagram_browser_screen.dart` — 2-column browse grid
- `app/test/hexagram_browser_screen_test.dart` — 5 widget tests (grid layout,
  all 64 scrollable, tap-to-detail, browse button present, button opens
  browser)

### Modified
- `app/lib/screens/question_form_screen.dart` — added "Browse Hexagrams"
  button

## Test Results
- Unit tests: 80/80 passed (incl. 5 new browser tests)
- Integration tests: 10/10 passed
