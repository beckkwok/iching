# Change Log 2026-10-01

## Task: Delete chat history (issue #45)

"Should provide a function to allow user to delete chat history."

### Design
- Each consultation card in the History tab gets a delete action (trash icon)
  with a confirmation dialog; deleting removes it from the database and the list
  immediately.
- `DatabaseService` gains `deleteConsultation(id)` and
  `deleteAllConsultations()` (the latter for a future "clear all").

### Changes
- `lib/services/database_service.dart`: `deleteConsultation(int id)` and
  `deleteAllConsultations()`.
- `lib/screens/history_screen.dart`: `_delete(consultation)` shows a confirm
  dialog, deletes via the DB, and removes it from `_consultations`; the card
  takes an `onDelete` callback and renders a trash `IconButton`.
- `lib/l10n/app_localizations.dart`: `delete`, `deleteConsultationTitle`,
  `deleteConsultationBody` (en/zh).
- Tests: `database_service_test` (delete one / delete all),
  `history_screen_test` (delete after confirmation, with a mutable fake DB).

### Verification
- `flutter analyze` — 3 pre-existing info lints (unrelated)
- `flutter test` — 202 tests pass
