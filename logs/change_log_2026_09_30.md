# Change Log 2026-09-30

## Task: Extend the starfield to all tabs and add meteors (issue #28)

Per the issue comment:
1. Extend the starfield background to the other tabs (History, Profile, Browse, Preference).
2. Add meteors to the background.
3. (No purple-shade tweaks required.)

### Design
- The immersive background is now owned by `HomeShell`: its body is a `Stack`
  with `TwinklingStars` behind the `IndexedStack`, shown only in dark mode. Every
  tab therefore shares the same continuous night sky.
- The tab screens' `Scaffold`s are made transparent so the sky shows through
  (`QuestionFormScreen`, `HexagramBrowserScreen`, `SettingsScreen`); History and
  Profile already render without a `Scaffold`.
- `TwinklingStars` gained shooting stars: `meteorCount` (default 6) meteors
  travel down-left on a fading gradient trail. Each meteor cycles through 8
  pre-generated trajectories (start point, direction, trail length), so it does
  not reappear in the same place.
- The dark theme's cards are now translucent
  (`cardTheme.color = surface @ 55%`) with no surface tint, so the sky is
  visible behind the cards on the History, Profile, Browse, and Cast-result
  screens.

### Changes
- `lib/widgets/twinkling_stars.dart`: added `_Meteor`/`_MeteorSpawn` data,
  `meteorCount`, and meteor painting (gradient trail + bright head).
- `lib/theme/app_theme.dart`: translucent `cardTheme` in the dark theme.
- `lib/screens/home_shell.dart`: `Stack` with `TwinklingStars` behind the tabs in
  dark mode.
- `lib/screens/question_form_screen.dart`: removed its local starfield/`Stack`
  (now provided by `HomeShell`); transparent `Scaffold`.
- `lib/screens/hexagram_browser_screen.dart`, `lib/screens/settings_screen.dart`:
  transparent `Scaffold`.
- Tests: `test/home_shell_test.dart` (dark shows / light hides the starfield),
  `test/twinkling_stars_test.dart` (meteors), and removed the now-obsolete
  question-form star tests.

### Verification
- `flutter analyze` — 3 pre-existing info lints (unrelated)
- `flutter test` — 192 tests pass
