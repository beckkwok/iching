# Change Log — 2026-07-08

## Prompt
When the user submits a question, create a screen to display the result of
`GuaGenerator`. Show the 卦象, and display 少陰 / 少陽 / 老陰 / 老陽 for each
爻.

## Thinking

### Design
1. **YaoLineType model** (`models/yao_line_type.dart`): enum of the four cast
   types — 老陰(6), 少陽(7), 少陰(8), 老陽(9) — with `value`, `label`,
   `isYang`, `isChanging`, and `fromValue()`.
2. **Three-coin casting** in `GuaGenerator`: each line sums three coins
   (2 = yin, 3 = yang) → 6/7/8/9 → the matching `YaoLineType`. The boolean
   `lines` are derived from `isYang`, so hexagram resolution is unchanged.
3. **GenerationResult** now carries `lineTypes` (bottom → top) plus a
   `lineTypeLabels` convenience getter. `formatContext` includes the labels
   for the LLM.
4. **CastResultScreen** (`screens/cast_result_screen.dart`): shows the 卦象
   card (第N卦, name, symbol) and one row per 爻 with the line pattern, 爻位
   (初..上), and the type label (老陰/少陽/少陰/老陽); changing lines get a
   `變` suffix and highlighted chip.
5. **Flow**: question form submit now navigates to `CastResultScreen` (instead
   of the hexagram detail screen).

## Files Changed

### Created
- `app/lib/models/yao_line_type.dart` — four yao line types
- `app/lib/screens/cast_result_screen.dart` — cast result display
- `app/test/cast_result_screen_test.dart` — 3 widget tests

### Modified
- `app/lib/services/gua_generator.dart` — three-coin casting, `lineTypes` on
  result, `resolveCast(..., lineTypes:)`, formatContext labels
- `app/lib/screens/question_form_screen.dart` — navigate to CastResultScreen
- `app/test/gua_generator_test.dart` — line type cast + resolveCast tests
- `app/test/question_form_screen_test.dart` — updated navigation assertions

## Test Results
- Unit tests: 86/86 passed
- Integration tests: 10/10 passed
