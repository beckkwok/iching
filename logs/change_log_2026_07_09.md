# Change Log — 2026-07-09

## Prompt
1. In `cast_result_screen.dart`, tapping the 卦象 card navigates to
   `hexagram_detail_screen.dart`.
2. In `hexagram_detail_screen.dart`, add a close button so the user can return
   to the cast result screen.

## Thinking

### Design
1. **CastResultScreen**: the 卦象 card is now wrapped in an `InkWell`
   (with `clipBehavior: Clip.antiAlias`) that `push`es
   `HexagramDetailScreen(gua: result.gua)`. Added a "Tap for details" hint.
2. **HexagramDetailScreen**: the AppBar `leading` is an explicit close (`X`)
   button that calls `Navigator.pop()`, returning to the previous screen
   (the cast result when opened from there).

## Files Changed

### Modified
- `app/lib/screens/cast_result_screen.dart` — tappable 卦象 card → detail
- `app/lib/screens/hexagram_detail_screen.dart` — close button in AppBar
- `app/test/cast_result_screen_test.dart` — tap card → detail test
- `app/test/hexagram_detail_screen_test.dart` — close button pops back test

## Test Results
- Unit tests: 88/88 passed
- Integration tests: 10/10 passed
