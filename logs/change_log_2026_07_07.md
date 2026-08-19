# Change Log — 2026-07-07

## Prompt
On the question form, when the user submits and has "generate hexagram"
checked, call `GuaGenerator` to generate a hexagram and display it in
`HexagramDetailScreen`. The chat screen is no longer part of this flow.

## Thinking

### Design
1. `_submit()` is now async. If hexagram generation is enabled and a DB is
   available:
   - Builds a `GuaGenerator(db)`.
   - Calls `generateRandom()` (casts 6 yao lines → resolves via
     `TrigramHexagramData`).
   - `pushReplacement` to `HexagramDetailScreen(gua: result.gua)`.
2. If generation is disabled (or no DB), shows a SnackBar hint instead of
   navigating anywhere (chat screen is out of the flow).
3. Submit button shows a loading state ("Casting..." + spinner) while the
   async cast runs.
4. Removed the `ChatScreen` import; updated the class doc comment.

## Files Changed

### Modified
- `app/lib/screens/question_form_screen.dart` — async submit → cast → detail
  screen; loading state; hint when generation disabled
- `app/test/question_form_screen_test.dart` — rewrote flow tests (submit
  opens detail screen; disabled shows hint; removed chat assertions)

## Test Results
- Unit tests: 81/81 passed
- Integration tests: 10/10 passed
