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

## Task: Consultation history (issue #8)

The History tab now lists the recorded consultations (question, hexagram, and
explanation), most recent first. Each consultation is persisted when the
explanation is generated.

### Changes
- **`lib/models/consultation.dart`** (new) — the consultation model.
- **`lib/services/database_service.dart`** — added a `consultations` table
  (schema v7 migration) and `createConsultation`/`getConsultations`.
- **`lib/screens/explanation_screen.dart`** — persists a consultation once the
  LLM explanation is generated (via a now-threaded `databaseService`).
- **`lib/screens/cast_result_screen.dart`** / **`question_form_screen.dart`** —
  thread the `databaseService` through to the explanation screen.
- **`lib/screens/history_screen.dart`** — replaced the placeholder with a list
  of consultations (empty state when none).
- **`lib/screens/home_shell.dart`** — passes the DB to the History tab.
- **`lib/l10n/app_localizations.dart`** — added `historyEmpty`.
- Tests: DB consultation round-trip/ordering, explanation saves a consultation,
  history screen list/empty state; updated the migration test.

### Verification
- `flutter analyze` — clean
- `flutter test` — 126 tests pass

### Follow-up: open the hexagram detail from history
Each consultation now stores the full hexagram JSON (`hexagram_content`), and
tapping a history entry opens `HexagramDetailScreen`.

- `Consultation` + `consultations` schema gained `hexagram_content`.
- `HistoryScreen` cards are tappable (navigate to the hexagram detail).
- Tests: history tap-to-detail; explanation saves the content; DB round-trip.

### Verification
- `flutter analyze` — clean
- `flutter test` — 127 tests pass

### Follow-up: migration for the hexagram_content column
Databases created at v7 before `hexagram_content` was added would fail with a
"no such column" SQLite exception when inserting a consultation.

- Bumped the schema to **v8** and added a migration that `ALTER TABLE`s the
  `consultations` table to add `hexagram_content` when it's missing.
- Added a migration test (v7 without the column → v8 with it, existing rows
  preserved).

### Verification
- `flutter analyze` — clean
- `flutter test` — 128 tests pass

## Task: User feedback (issue #2)

After the LLM response, the user can rate the answer (1-5 stars) and leave a
comment; the feedback is stored on the consultation.

### Changes
- **`lib/models/consultation.dart`** — added nullable `rating` and `comment`.
- **`lib/services/database_service.dart`** — added `rating`/`comment` columns
  (schema **v9** migration) and `updateConsultationFeedback`.
- **`lib/screens/explanation_screen.dart`** — added a feedback card (5-star
  rating + comment + submit) below the explanation, and persists it via
  `updateConsultationFeedback`.
- **`lib/l10n/app_localizations.dart`** — added feedback strings (en/zh).
- Tests: DB feedback round-trip; explanation feedback submission.

### Verification
- `flutter analyze` — clean
- `flutter test` — 130 tests pass
