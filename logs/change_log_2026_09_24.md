# Change Log 2026-09-24

## Task: Dark mode toggle (issue #30, part of #28)

Add a light/dark theme toggle. The app defaults to dark. The Material dark
theme is seeded from deep purple `#673AB7`, and the forui widgets switch to
`FColors.neutralDark` in dark mode.

### Prompt / intent
- Optional light/dark toggle (default dark), persisted in the settings table.
- Purple `#673AB7` (deep purple) used for the dark Material scheme.
- Follow-ups logged separately: purple gradient buttons (#31) and the
  twinkling-star background on the Ask screen (#32).

### Changes
- `lib/models/theme_preference.dart` (new): `ThemePreference` enum (dark/light)
  with `settingsKey` (`theme_mode`) and `fromCode` (defaults to dark).
- `lib/theme/theme_controller.dart` (new): `ThemeController` (ChangeNotifier,
  maps preference to `ThemeMode`) and `ThemeScope` (InheritedNotifier), mirroring
  `LocaleController`/`LocaleScope`.
- `lib/main.dart`: seeds `ThemeController` from the saved setting; adds
  `darkTheme` (deep purple seed, dark brightness), `themeMode`, and switches the
  forui `FTheme` colors on `Theme.of(context).brightness`.
- `lib/l10n/app_localizations.dart`: added `theme`, `dark`, `light` (en/zh).
- `lib/screens/settings_screen.dart`: added a Theme section with a light/dark
  `RadioGroup`, persisted via `DatabaseService.setSetting` and applied
  immediately via `ThemeScope`.
- `test/theme_preference_test.dart` (new), `test/theme_controller_test.dart`
  (new): unit + widget tests.
- `test/settings_screen_test.dart`: theme selector tests (options, default,
  persistence, saved-preference reflection).
- `test/widget_test.dart`: passes a `ThemeController` to `MyApp`.

### Verification
- `flutter analyze` — clean
- `flutter test` — 155 tests pass

## Task: Purple gradient buttons (issue #31, part of #28)

Style the primary call-to-action buttons with a deep-purple gradient fill.

### Prompt / intent
- Purple `#673AB7` (deep purple) with a lighter shade, as a **gradient**
  (purple → lighter purple).

### Changes
- `lib/widgets/gradient_button.dart` (new): a reusable `GradientButton`
  (label + optional icon, gradient `#673AB7` → `#AB47BC`, ripple, disabled
  opacity) replacing `FilledButton`/`FilledButton.icon` for primary CTAs.
- Replaced primary CTAs with `GradientButton`:
  - `question_form_screen.dart` (Submit Question)
  - `cast_result_screen.dart` (Get Explanation)
  - `explanation_screen.dart` (Submit feedback)
  - `prompt_editor_screen.dart` (Save)
  - `model_selection_screen.dart` (Confirm & Download, Continue anyway)
  - Loading spinners inside these buttons are now white for contrast.
- `test/gradient_button_test.dart` (new): label/icon render, enabled/disabled
  tap, and gradient-fill verification.

### Verification
- `flutter analyze` — clean
- `flutter test` — 147 tests pass

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
- `flutter test` — 146 tests pass

## Task: Chinese font (LXGW WenKai Mono TC) (issue #33, part of #28)

Bundle the LXGW WenKai Mono TC (Traditional Chinese kai-style monospace) font
as a fallback so Chinese text renders in it while Latin text keeps the default.

### Prompt / intent
- Chinese text should use LXGW WenKai Mono TC.
- Size-conscious: subset the font to only the characters the app uses (~1,680
  unique CJK chars) instead of bundling the full ~13 MB font.

### Changes
- Downloaded `LXGWWenKaiMonoTC-Regular.ttf` and `-Bold.ttf` from the Google Fonts
  source (`aaronbell/LxgwWenkaiTC`, commit `a5cf76f`), then subset them with
  `fontTools.subset` to the app's used characters (~1.18 MB each, 1,873 glyphs).
- `app/assets/fonts/LXGWWenKaiMonoTC-{Regular,Bold}.ttf` (new): subset fonts.
- `app/pubspec.yaml`: registered the `LXGWWenKaiMonoTC` family (weights 400/700).
- `lib/theme/app_theme.dart` (new): `chineseFontFallback`, `buildLightTheme()`,
  `buildDarkTheme()`, and `buildForuiTheme()` (forui typography also carries the
  fallback).
- `lib/main.dart`: uses the theme builders; sets `fontFamilyFallback` to
  `LXGWWenKaiMonoTC` on the Material themes and the forui theme.
- `test/app_theme_test.dart` (new): verifies the fallback is configured on both
  themes and the dark/light brightness.

### Verification
- `flutter analyze` — clean (2 pre-existing info lints unrelated to this change)
- `flutter test` — 166 tests pass

## Task: Layered sky background gradient

Change the twinkling-star background from pure black `#000000` to a layered
vertical linear gradient (deepest `#0B0914` at the top → `#12101E` → lifted
`#1D1A33` at the bottom), giving the night sky more depth.

### Changes
- `lib/widgets/twinkling_stars.dart`: sky now painted with
  `TwinklingStars.skyGradient` (a `LinearGradient`) instead of a flat color.
- `test/twinkling_stars_test.dart`: assert the gradient includes `#12101E`.

### Verification
- `flutter analyze` — clean
- `flutter test` — 167 tests pass

## Task: Ancient-gold text in the dark theme

Use a soft antique gold (`#D4AF37`) for text across the dark theme.

### Changes
- `lib/theme/app_theme.dart`: added the `ancientGold` constant. `buildDarkTheme()`
  now overrides `onSurface`/`onSurfaceVariant` and applies gold to the text
  theme; `buildForuiTheme()` sets the gold `foreground` in dark mode.
- `test/app_theme_test.dart`: dark text is gold; light stays default; dark forui
  foreground is gold.

### Verification
- `flutter analyze` — clean
- `flutter test` — 170 tests pass

## Task: Immersive "glowing jade" gradient button

Redesign the primary button per the immersive-UI guideline: a translucent
deep-purple fill so the starfield shows through, a fine gold border, a soft gold
glow, and a press-down animation with haptic feedback.

### Changes
- `lib/widgets/gradient_button.dart`: now a `StatefulWidget`.
  - Dark mode: translucent purple-gradient fill (35% → 22% opacity), 1px gold
    border (`#D4AF37` @ 55%), gold glow (`BoxShadow`, blur 24 / spread 2).
  - Light mode: keeps the solid purple gradient for contrast.
  - Press: `AnimatedScale` to 0.95 + `HapticFeedback.lightImpact()`.
  - Fix: the content used a stray `Center` that made the button expand to fill
    its parent, so the glow looked like a big rectangle. Replaced with
    `Align(widthFactor: 1, heightFactor: 1)` so the button hugs its content
    (like Material buttons) and the glow follows the rounded shape.
- `test/gradient_button_test.dart`: light/dark decoration, glow, press scale,
  and content sizing.

### Verification
- `flutter analyze` — clean
- `flutter test` — 173 tests pass

## Task: 結果 section on the cast result page

Add a quick, non-LLM reading to the cast result page.

### Prompt / intent
- A 結果 section containing 象徵意義 and 爻辭 (the 現代白話／通解 interpretation).
- Highlight the 生活與占事常見象徵 entry matching the question type.
- Highlight the changing (老陰/老陽) lines.

### Changes
- `lib/services/hexagram_reading.dart` (new): `HexagramReading` helpers —
  `isModern`/`modern`, `lifeKeyForQuestionType`, `linePositionLabel`,
  `changingPositions`.
- `lib/screens/cast_result_screen.dart`: added a `questionType` param and the
  `_ResultSection` (象徵意義 + 爻辭), with `_Highlighted` for the question-type
  life-symbol entry and the changing lines' 爻辭解讀.
- `lib/screens/question_form_screen.dart`: pass the selected `QuestionType`.
- `lib/l10n/app_localizations.dart`: added `resultSection` (結果 / Result).
- Tests: `test/hexagram_reading_test.dart` (new); cast result section test.

### Verification
- `flutter analyze` — clean
- `flutter test` — 180 tests pass
