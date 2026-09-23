# Change Log 2026-09-23

## Task: Show the last visited hexagram in the browser (issue #11)

In the Browse tab, the most recently visited hexagram is now shown in a header
above the grid; tapping a hexagram card records it as the last visited.

### Changes
- `lib/screens/hexagram_browser_screen.dart`:
  - Added an optional `databaseService` and a `_LastVisitedHeader` card that
    shows the last visited hexagram (name + symbol), tappable to reopen it.
  - Tapping a card now records its code under the `last_visited_gua` setting
    and updates the header.
- `lib/l10n/app_localizations.dart`: added `lastVisited` (en/zh).
- `lib/screens/home_shell.dart`: passes `databaseService` to the Browse tab.
- `test/hexagram_browser_screen_test.dart`: added tests for the header display
  and the persistence of the last visited hexagram.

### Verification
- `flutter analyze` — clean
- `flutter test` — 120 tests pass
