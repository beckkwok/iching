# Change Log — 2026-11-11

## Task: Markdown interpretation + full history text

### Prompt

> 1. I want the interpretation text box support markdown
> 2. In the history view, I cannot see the full text of interpretation

### Thinking

- Added a maintained Markdown renderer (`flutter_markdown_plus`) instead of
  writing a partial parser; the new system prompt outputs headings, lists,
  bold text and horizontal rules.
- Reused one themed `MarkdownText` widget for the explanation screen, the
  consultation detail and the history cards so styling stays consistent.
- The history card previously capped the explanation at 3 lines with an
  ellipsis. Removed the cap and render the complete explanation; history cards
  use the compact, non-selectable style, while the detail/explanation screens
  keep selection enabled.

### Files changed

- `app/pubspec.yaml`, `app/pubspec.lock`
  - Added `flutter_markdown_plus: ^1.0.12`.
- `app/lib/widgets/markdown_text.dart` (new)
  - Themed `MarkdownBody` wrapper with compact/selectable options.
- `app/lib/screens/explanation_screen.dart`
  - Renders the generated interpretation as Markdown.
- `app/lib/screens/consultation_detail_screen.dart`
  - Renders the saved interpretation as Markdown.
- `app/lib/screens/history_screen.dart`
  - Shows the full explanation instead of a 3-line preview, rendered as
    Markdown.
- `app/test/explanation_screen_test.dart`
  - Verifies the Markdown widget receives the explanation and renders headings
    and bold text.
- `app/test/history_screen_test.dart`
  - Verifies the history card receives the complete explanation without
    truncation.

### Verification

- `flutter analyze`: 3 pre-existing infos only.
- `flutter test`: 288 passing.
- Release build succeeds:
  `flutter build apk --dart-define-from-file=firebase.local.json`.
