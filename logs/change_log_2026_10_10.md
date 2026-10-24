# Change Log 2026-10-10

## Task: #60 slice — medallion asset for Ask screen (#65)

Wire the author-supplied gold taiji artwork (`app/assets/images/taichi.png`,
641x699) for the Ask emblem: declare it in `pubspec.yaml` and verify it
loads in both modes. Display note: corners are opaque white, so the emblem
must be shown center-cropped in a circle (`ClipOval` + `BoxFit.cover`) — the
Ask assembly slice (#66) handles that.

## Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green

## Task: #60 slice — assemble Ask screen to mockup (#66)

Implements the author's spec answers: 110px medallion (`medallion.png`,
center-cropped in a circle) with champagne glow; spec-exact `GlassCard`
(obsidian `#13131A` @ 0.6 dark / parchment `#F9F6EE` light, champagne
`#E6D5B8` @ 0.3 / bronze `#C5B358` borders, padding 16); mode-aware input
fills (translucent dark / white light) with white-@-0.3 hints in dark mode;
gold dropdown arrow; outer padding 24h/16v; 20px section spacing.

Deferred to later slices: solid-gold submit + dark text and purple sweep
(#73), Noto Serif TC headers (#72). Sky gradient left as-is (already
obsidian-equivalent); submit/validation/casting logic untouched. The taller
form required scroll-into-view before tapping submit in
`question_form_screen_test.dart` (+ helper) and `privacy_test.dart`.

### Follow-up refinements (from device screenshot review)

- Medallion wrapped in `Center` (the stretch column was flattening it to an
  oval) with a refined champagne border + layered glow.
- Explicit champagne `enabledBorder`/`focusedBorder` on both inputs (shared
  `_fieldBorder` helper).
- All four controls (type, question, method, submit) unified inside a single
  `GlassCard`; the card gains a luminosity gradient, layered outer glow, and a
  crisper border.

## Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (216 pass)

## Follow-up: submit matches pills, pills fully oval (#66)

- Submit (`GradientButton`) takes optional `gradientColors`/`foregroundColor`
  (defaults preserve existing behavior); the Ask submit uses the champagne →
  bronze gradient with black text, matching the selected casting pill.
- The joined `SegmentedButton` is replaced by two separated `_MethodPill`
  toggles with an 8px gap — each fully oval on both sides; selected shows a
  check, gold gradient fill and black text.
- Tests updated/added for the pills and custom button colors. Note:
  `find.byType(Container)` also matches `AnimatedContainer` subtypes, so the
  glass-fill assertion now selects by its exact gradient.
- Medallion crop pinned to the top (`Alignment.topCenter`): the coin sits
  high in its frame with a white margin below, which showed as a white band
  inside the circle.

## Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (217 pass)

## Task: #60 slice — Noto Serif TC headers (#72)

Bundle subsetted Noto Serif TC (Regular + Bold, ~0.76MB each covering the
app's Latin + CJK glyph set, OFL via Google Fonts) and use it as the
`fontFamily` for the Ask title and section labels. Everything else keeps the
LXGW fallback chain.

## Task: #60 slice — solid gold submit + purple sweep (#73)

Make `GradientButton` a solid rich-gold fill in **both** modes with dark text,
matching the author's spec §3 + §5.

- `gradient_button.dart`: `start` is now champagne `#E6D5B8`, `end` deeper
  bronze `#C5B358`; new `ink` `#13131A` is the default `foregroundColor`.
  Dropped the dark-mode translucent branch (and white text / gold border):
  `_decoration()` is now mode-independent and always keeps the soft gold
  `#E6D5B8` glow. Press-scale + haptic unchanged.
- Ask submit (`question_form_screen.dart`) dropped its now-redundant
  `gradientColors`/`foregroundColor` overrides and its spinner uses
  `GradientButton.ink`.
- `prompt_editor_screen.dart` save-spinner changed from white to
  `GradientButton.ink` (white was invisible on the gold fill).
- Purple sweep: the only remaining reference is the `GradientButton` doc
  comment (rewritten). The single other hit is the classical I-Ching text in
  `assets/hexagrams/gua_47.json` ("purple knee bands") — content, not UI, left
  as-is.
- `gradient_button_test.dart` rewritten: solid gradient + dark ink asserted in
  both modes; the old translucent/white light-mode assertions replaced.

## Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (218 pass)

## Task: store + show the full consultation record (#47)

The history now keeps and displays the complete record instead of only the
original hexagram.

- `Consultation` gains `lineTypes` (the six 老陰/少陽/少陰/老陽 values) and the
  changed hexagram (`code` / `name` / `content`), all nullable/defaulted for
  legacy rows. `toMap`/`fromMap` serialize them (`line_types` as a JSON array;
  malformed JSON falls back to empty) and `==`/`hashCode` include them.
- DB **v13** adds `line_types`, `changed_hexagram_code`,
  `changed_hexagram_name`, `changed_hexagram_content` to `consultations`
  (idempotent `ALTER`s guarded by `PRAGMA table_info`). `createConsultation`
  now round-trips through `fromMap` so no field is dropped.
- `ExplanationScreen` persists the cast's line types and `changedGua` when it
  saves the consultation.
- New `ConsultationDetailScreen` shows: question/type/date, original hexagram
  (+ yao lines), changed hexagram, full LLM explanation and feedback. The
  history card shows the changed hexagram and opens this screen on tap.
- Added the `consultationDetail` l10n key; no other strings added.

### Tests

- `consultation_test.dart` — full-record round-trip, legacy defaults,
  malformed `line_types`.
- `database_service_test.dart` — full cast persists through SQLite.
- `migration_v4_test.dart` — v12 → v13 adds the columns and preserves rows.
- `explanation_screen_test.dart` — the saved consultation includes the
  changed hexagram and line types.
- `history_screen_test.dart` — changed hexagram shown; tap opens the full
  record.

## Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (225 pass)
