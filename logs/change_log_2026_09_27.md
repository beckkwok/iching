# Change Log 2026-09-27

## Task: Add loading screen animation (issue #29)

Replace the plain `CircularProgressIndicator` on the startup screen with an
immersive yao animation: six lines morphing yin↔yang with independent random
timing, above the loading message and a hexagram name that fades from one to the
next.

### Prompt / intent
- Issue #29: "Build the bi-gram from ying to yang. And then yang to ying";
  "6 bi-gram are random loading"; "Loading text will be animated and replaced
  with some pre-loaded hexagram name".

### Design
- A self-contained `YaoLoadingAnimation` widget (no LLM/DB dependency), driven by
  one repeating `AnimationController`.
- Each of the six lines oscillates `yin -> yang -> yin` on a sine wave; per-line
  random phase + speed (0.6–1.4×) make the six lines load independently.
- A yin line is drawn as two bars with an animated centre gap; at gap 0 the bars
  meet and read as a single yang line, giving a smooth morph.
- Hexagram names cycle on a `Timer.periodic` with an `AnimatedSwitcher` fade,
  defaulting to the 64 classical names from `TrigramHexagramData.all`.

### Changes
- `lib/widgets/yao_loading_animation.dart` (new): the animation widget.
- `lib/screens/model_selection_screen.dart`: the `initialising` and `loading`
  phases now render `YaoLoadingAnimation` (checking-setup / loading-model
  messages) instead of a spinner.
- `test/yao_loading_animation_test.dart` (new): renders six lines + message,
  cycles names, and wraps back to the first name.

### Verification
- `flutter analyze` — 3 pre-existing info lints (unrelated to this change)
- `flutter test` — 190 tests pass

## Task: Reuse the loading animation while generating the explanation

Show the same immersive yao animation while the LLM is generating the
interpretation, instead of a plain spinner.

### Changes
- `lib/l10n/app_localizations.dart`: added `generatingExplanation`
  ("Consulting the hexagram..." / "正在為您解讀…").
- `lib/screens/explanation_screen.dart`: the loading state now renders
  `YaoLoadingAnimation` with `generatingExplanation`.
- `test/explanation_screen_test.dart`: asserts the animation shows while
  generating and disappears once the explanation arrives.

## Task: Comments on less-confident issues

Assessed all open issues and posted clarifying comments on the ones with open
design questions: #5 (persistence/session/context), #10 (LLM vs heuristics,
blocking), #14 (pad breakpoints), #20 ("Full Generate" undefined), #22
(interpreter storage), #26 (per-topic schema), #27 (duplicate of #23, storage
mapping), #28 (what remains after the sub-items).
