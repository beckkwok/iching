# Change Log — 2026-07-01

## Prompt
1. Build a constant mapping table from the provided CSV (low trigram + high trigram → hexagram) to prepare for revamping `gua_generator.dart`.
2. Update the `GeneratorMethod` enum in `gua_generator.dart`:
   - Remove `automatic`
   - Rename `userRequested` → `manual`
   - Rename `randomCast` → `systemGenerated`

## Thinking

### CSV analysis
The CSV maps every (lower trigram, upper trigram) pair to a hexagram:
- Trigram codes are binary line patterns (bottom line = LSB): 天=乾=7(111), 澤=兌=6(110), 火=離=5(101), 雷=震=4(100), 風=巽=3(011), 水=坎=2(010), 山=艮=1(001), 地=坤=0(000).
- `result_code = low_code * 8 + high_code` (verified across all 64 rows, e.g. 7下+6上 → 62 澤天夬).
- `result_name` is the classical hexagram name (e.g. "乾為天").

### Design decisions
1. **Model**: `TrigramHexagram` (`models/trigram_hexagram.dart`) with `lowCode`, `lowDesc`, `highCode`, `highName`, `resultCode`, `resultName` + `toMap`/`fromMap`/`==`/`hashCode`.
2. **Constant data**: `TrigramHexagramData` (`data/trigram_hexagram_data.dart`) with all 64 entries transcribed verbatim from the CSV, plus `byCodes()` and `byResultCode()` lookups.
3. **Enum rename**: `GeneratorMethod` now only has `manual` (was `userRequested`) and `systemGenerated` (was `randomCast`). `automatic` removed. Updated `_methodHeader`, all call sites, tests, and AGENTS.md.
4. **1-based codes (revision)**: per user request, trigram codes shifted to 1–8 (地=1 … 天=8) and `resultCode` = `(lowCode - 1) * 8 + highCode`, spanning 1–64 (乾為天=64, 坤為地=1, 地風升=25). Model docs, data file, and tests updated.
5. **`linesToCode()`**: new static method in `TrigramHexagramData` mapping three boolean yao lines (bottom→top, true=yang/1, false=yin/0) to the 1-based trigram code, e.g. `linesToCode(true,true,true) == 8` (天), `linesToCode(false,false,false) == 1` (地). Added 3 tests covering all 8 patterns, uniqueness, and consistency with the data entries.

## Files Changed

### Created
- `app/lib/models/trigram_hexagram.dart` — trigram→hexagram mapping model
- `app/lib/data/trigram_hexagram_data.dart` — 64-entry constant mapping table + lookups
- `app/test/trigram_hexagram_data_test.dart` — validates count, uniqueness, formula, lookups, round-trip

### Modified
- `app/lib/services/gua_generator.dart` — enum renamed (`manual`, `systemGenerated`), removed `automatic`, updated `_methodHeader` + call sites
- `app/test/gua_generator_test.dart` — updated enum references
- `AGENTS.md` — updated enum documentation

## Test Results
- Unit tests: 58/58 passed (incl. 12 mapping-table tests)
- Integration tests: 10/10 passed
