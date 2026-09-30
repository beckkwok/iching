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
- `TwinklingStars` gained shooting stars: `meteorCount` (default 10) meteors
  travel down-left on a fading gradient trail, with a wide speed range (0.2–1.5)
  so some are slow drifters and some are fast streaks. Each meteor cycles
  through 8 pre-generated trajectories (start point, direction, trail length),
  so it does not reappear in the same place.
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

## Task: Replace star rating with emoji reactions (issue #27)

Per the issue comment:
1. #23 is closed as a duplicate of #27.
2. No data migration needed — just store the reaction.
3. Emoji set: 😄 (happy), ❤️ (love), 😔 (sad), 😡 (angry), 😲 (surprised),
   ❤️‍🩹 (healing), with tooltips explaining each.
The reactions are fed to the agent-memory extraction.

### Design
- Feedback is stored as a stable reaction **key** (`reaction TEXT`), replacing the
  old 1-5 `rating`. The `rating` column is left in place but unused.
- `extractMemory` receives the reaction's **emoji** so the LLM can read the
  feeling directly.

### Changes
- `lib/models/reaction.dart` (new): `Reaction` enum (`key`, `emoji`,
  `fromKey`).
- `lib/models/consultation.dart`: `rating` → `reaction` (`String?`), incl.
  `toMap`/`fromMap`/`==`/`hashCode`.
- `lib/services/database_service.dart`: DB version 11; `reaction TEXT` column +
  `_addConsultationReactionColumn` migration; `createConsultation` /
  `updateConsultationFeedback` use `reaction`.
- `lib/services/llm_service.dart`: `extractMemory` / `buildMemoryPrompt` accept
  an optional `reaction`.
- `lib/l10n/app_localizations.dart`: reaction tooltips (`reactionHappy`, …);
  the feedback section is renamed in Chinese — title 意見回饋 → 意見 and thanks
  感謝您的回饋！ → 感謝您的意見！ (it is the user's own thinking about the
  hexagram, kept for reference).
- `lib/screens/explanation_screen.dart`: the star row is replaced by tappable
  emoji reaction buttons with tooltips; feedback + memory pass the reaction.
- `lib/screens/history_screen.dart`: shows the reaction emoji instead of stars.
- `AGENTS.md`: schema doc updated (`reaction` replaces `rating`).
- Tests: `test/reaction_test.dart` (new); updated `database_service_test`,
  `explanation_screen_test`, `history_screen_test`, `llm_service_test`.

### Verification
- `flutter analyze` — 3 pre-existing info lints (unrelated)
- `flutter test` — 196 tests pass
