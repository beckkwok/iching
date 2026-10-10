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

## Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (216 pass)
