# Change Log — 2026-11-10

## Issue #90 — interpretation rules by number of changing lines

### Prompt

> I've updated issue 90, please see if you have confident to work on and then
> start work on this.

### Decision / thinking

The author confirmed the conventional 朱熹 rule and answered the open questions:

- 0 changing lines: read 本卦卦辭.
- 1: read the original changing line's 爻辭.
- 2: read both original changing lines; the upper line is primary.
- 3: read 本卦卦辭 + 變卦卦辭.
- 4: read the two stable lines in the changed hexagram.
- 5: read the one stable line in the changed hexagram.
- 6: read 變卦卦辭; 乾 uses 用九 and 坤 uses 用六.
- Send only the selected text(s), not the whole hexagram context.
- One rule for every question type.

Implementation keeps the rule summaries in one table in `GuaGenerator` and
selects the matching text in one helper. The explanation prompt now carries the
selected text plus explicit 本卦 / 變卦 / 變爻 labels. The existing `formatContext`
is kept for callers/tests that need the full hexagram.

### Files changed

- `app/lib/services/gua_generator.dart`
  - Added `_interpretationRuleSummaries` (0–6 table).
  - Added `formatInterpretationContext()` plus helpers for judgments, lines,
    stable-line indices, changing-line indices, and the 用九/用六 special line.
- `app/lib/services/local_gemma_backend.dart`
  - Uses `formatInterpretationContext()` for the explanation prompt.
- `app/lib/services/firebase_ai_backend.dart`
  - Uses `formatInterpretationContext()` for the explanation prompt.
- `app/test/gua_generator_test.dart`
  - Added controlled fixtures and tests for 0, 1, 2, 3, 4, 5, 6, including
    乾 用九 and 坤 用六.
- `app/test/firebase_ai_backend_test.dart`
  - Asserts the Firebase explanation prompt carries the new rule/selection
    context.

### Verification

- `flutter analyze`: 3 pre-existing infos only.
- `flutter test`: 282 passing.

## Task: decision-advisor system instruction

- Replaced the default system prompt with the expert I-Ching consultant /
  decision-making advisor instruction, including the 6 question-validation
  principles, 朱熹 changing-line priorities, and the 4-part Markdown output
  template with a strict 500-word limit.
- Updated the explanation prompt to follow the system instruction and the
  500-word limit; removed the conflicting 3-5 sentence instruction.
- Tests: default prompt content + no 3-5 sentence instruction; 284 passing.
