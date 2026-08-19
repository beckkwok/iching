# Change Log — 2026-07-04

## Prompt
Build a screen to display the hexagram content in a card layout.

## Thinking

### Design
1. **HexagramDetailScreen** (`screens/hexagram_detail_screen.dart`): a
   full-screen detail view of one hexagram, laid out as a scrollable list of
   cards. Shows every field of the hexagram's JSON content:
   - Header card: 第N卦 badge, name, the 6-line yao pattern (drawn
     bottom-to-top), and 卦象 symbol.
   - 卦辭, 彖傳, 大象傳 section cards.
   - 爻辭 card listing each line (position chip, text, 小象傳).
   - 象徵意義 card (基本卦象, 主要象徵, 生活與占事常見象徵, 總結).
   - 不同人解讀 card (per commentator: 卦辭解讀 + per-line 爻辭解讀).
   - 備註 card.
2. **GuaCard** now opens the detail screen when tapped (wrapped in
   InkWell/Material), so users can drill down from a chat's GuaCard into the
   full content.
3. Shared line-pattern helper (`TrigramHexagramData.linesFromSymbol`) reused
   by the header card.

## Files Changed

### Created
- `app/lib/screens/hexagram_detail_screen.dart` — card-layout detail screen
- `app/test/hexagram_detail_screen_test.dart` — 6 widget tests (header,
  sections, lines, symbolic meaning/interpretations, unparseable content,
  GuaCard tap-to-open)

### Modified
- `app/lib/widgets/gua_card.dart` — tappable, opens `HexagramDetailScreen`

## Test Results
- Unit tests: 75/75 passed (incl. 6 new detail-screen tests)
- Integration tests: 10/10 passed
