# Change Log — 2026-07-06

## Prompt
1. Change the hexagram browser from 2 fixed columns to fill columns.
2. Hexagram 51 example: 卦象 should be "䷱（下震上震）", 卦名 "震為雷" —
   suspicion that the JSON file isn't being read when displaying.
3. Hexagram detail screen shows "Unable to read the hexagram content".

## Root Cause

The app's persistent SQLite DB (`iching.db`) still held **old pre-JSON gua
rows** (plain-text `gua_content`, pinyin names like "震 (Zhèn)"). `Gua.content`
parses JSON, so those rows returned `null` → the detail screen showed "Unable
to read". The seeder only fills empty tables, and the v3 migration preserved
existing rows, so the stale data never got replaced.

The JSON assets themselves were correct (verified `gua_51.json` =
卦名 震為雷, 卦象 ䷱（下震上震）).

## Fix

1. **DB v4 migration**: bump `_databaseVersion` to 4; in `_onUpgrade`, when
   `oldVersion < 4`, `DELETE FROM gua` so `GuaSeeder` re-seeds from the JSON
   assets on next launch. Added `test/migration_v4_test.dart` proving a v2 DB
   with old rows upgrades to v4, clears them, and re-seeds JSON correctly.
2. **Fill columns**: browser grid now uses
   `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180)` instead
   of fixed 2 columns, so cards fill available width responsively.
3. Updated browser test to assert the max-extent delegate.

## Files Changed

### Modified
- `app/lib/services/database_service.dart` — `_databaseVersion` → 4, v4
  migration clears gua table
- `app/lib/screens/hexagram_browser_screen.dart` — fill-column grid
- `app/test/hexagram_browser_screen_test.dart` — updated grid assertion

### Created
- `app/test/migration_v4_test.dart` — v2→v4 migration + re-seed test

## Test Results
- Unit tests: 81/81 passed (incl. migration test)
- Integration tests: 10/10 passed
