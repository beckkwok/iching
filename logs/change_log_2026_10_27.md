# Change Log 2026-10-27

## Task: LLM context for changing lines + changed hexagram (#79)

Part of #5 (context-only slice; independent of the pending progressive-UI
decisions). Adds pure context builders so a follow-up LLM step can interpret the
changing lines (變爻) and the changed hexagram (變卦).

### Changes

- `app/lib/services/gua_generator.dart`
  - New `formatChangingLinesContext(result)` — lists each changing line
    (老陰/老陽) with its 爻位, 爻辭 and 小象傳. Empty when there are no changing
    lines.
  - New `formatChangedHexagramContext(result)` — the changed hexagram's name,
    changed line pattern, 卦辭, 彖傳, 大象傳 and 象徵總結. Empty when there is no
    changed hexagram.
  - Extracted `_writeContent` shared by `formatContext` and the new builders.
- `app/test/gua_generator_test.dart` — added a fixture with 爻辭/小象傳 and tests
  for both builders (changing-line inclusion/exclusion, changed-hexagram
  details, and the empty cases).

### Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (233 pass)
