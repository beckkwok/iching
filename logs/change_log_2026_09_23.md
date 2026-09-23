# Change Log 2026-09-23

## Task: Show recently viewed hexagrams in the browser (issue #11)

In the Browse tab, the most recently visited hexagrams (up to 3) are shown in a
header above the grid; tapping a hexagram card records it as the most recent.

### Changes
- `lib/screens/hexagram_browser_screen.dart`:
  - Added an optional `databaseService` and a `_RecentHeader` with up to three
    tappable `_RecentChip`s showing the recently viewed hexagrams (name +
    symbol).
  - Tapping a card prepends its code to the recently-viewed list
    (de-duplicated, trimmed to 3) and persists it under the
    `last_visited_guas` setting (comma-separated).
- `lib/l10n/app_localizations.dart`: added `recentlyViewed` (en/zh).
- `lib/screens/home_shell.dart`: passes `databaseService` to the Browse tab.
- `test/hexagram_browser_screen_test.dart`: added tests for the header display,
  recording, and the "last 3, most recent first" behaviour.

### Verification
- `flutter analyze` — clean
- `flutter test` — 121 tests pass
