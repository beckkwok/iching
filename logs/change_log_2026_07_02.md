# Change Log — 2026-07-02

## Prompt
Revise `gua_generator`:
- No longer pick a random number from 1–64.
- Generate 6 booleans (bottom → top) as the yao cast, then use
  `TrigramHexagramData` to resolve the actual hexagram.
- Store the 6 boolean result so it can be used to interpret the cast.

## Thinking

### Design
1. **Cast model**: `GenerationResult` now carries `lines` (`List<bool>`,
   6 elements, index 0 = bottom line, index 5 = top line) with `hasCast`.
   Manual lookups keep an empty list.
2. **generateRandom** casts six random booleans, splits them into the lower
   trigram (indices 0–2) and upper trigram (indices 3–5), derives each
   trigram code via `TrigramHexagramData.linesToCode`, looks up the hexagram
   via `byCodes`, then resolves the matching seeded `Gua`:
   - Prefer exact name match (`卦名` == mapping `resultName`, e.g. "地風升").
   - Fall back to comparing each gua's 卦象-derived 6-line pattern.
3. **Shared parser**: moved the 卦象 → line pattern logic into
   `TrigramHexagramData.linesFromSymbol`, reused by `GuaCard`.
4. **resolveCast**: public helper for a fixed 6-line cast (throws
   `ArgumentError` if not exactly 6 lines).
5. **formatContext** now includes `Cast lines (bottom to top): yang, yin, ...`
   so the LLM can interpret the actual cast.
6. Fixed a subtle Dart gotcha: `List ==` is identity, so line-pattern matching
   uses element-wise `_listsEqual`.

### Test fixture note
The generator test fixtures now author each gua with the mapping's classical
`卦名` (e.g. "乾為天") and a unique trigram combination, matching how the real
`gua_<n>.json` files are authored. findInText tests updated accordingly.

## Files Changed

### Modified
- `app/lib/data/trigram_hexagram_data.dart` — added `trigramLinePatterns` +
  `linesFromSymbol()`
- `app/lib/services/gua_generator.dart` — `GenerationResult.lines`,
  `generateRandom` (6-boolean cast), `resolveCast`, `_resolveGua`,
  `_listsEqual`, `formatContext` cast lines
- `app/lib/widgets/gua_card.dart` — uses shared `linesFromSymbol`
- `app/test/gua_generator_test.dart` — distinct trigram fixtures, new cast
  tests (6 lines, mapping consistency, fixed 乾為天/坤為地 casts, cast lines
  in context), updated findInText tests

## Test Results
- Unit tests: 64/64 passed
- Integration tests: 10/10 passed
