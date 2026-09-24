# Change Log 2026-09-24

## Task: Twinkling star background on the Ask screen (issue #32, part of #28)

Add an animated twinkling-star background to the first (Ask) screen in dark
mode, giving the "black sky with stars on/off" immersive effect.

### Prompt / intent
- Black background with lights as stars fading on and off.
- Start on the first (Ask) screen; may extend to more screens later if the
  effect works well.

### Changes
- `lib/widgets/twinkling_stars.dart` (new): `TwinklingStars` — an animated
  `CustomPaint` that paints a black sky and N stars whose opacity follows a
  per-star sine wave (random phase/speed), driven by a repeating
  `AnimationController`.
- `lib/screens/question_form_screen.dart`: wraps the form in a `Stack` with
  `TwinklingStars` behind the content, shown only in dark mode
  (`Brightness.dark`).
- `test/twinkling_stars_test.dart` (new): renders a canvas and repaints over
  time.
- `test/question_form_screen_test.dart`: dark-mode shows the stars, light-mode
  hides them.

### Verification
- `flutter analyze` — clean
- `flutter test` — 147 tests pass
