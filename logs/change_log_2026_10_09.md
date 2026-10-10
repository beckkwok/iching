# Change Log 2026-10-09

## Task: #60 slice — gold-forward app theme (#61)

Gold seeds for both Material schemes (`ancientGold`), so the bottom-nav
active tint (`colorScheme.primary` via `_NavIcon`) is gold in both modes.
Forui themes untouched.

## Task: #60 slice — gold GradientButton (#62)

`start`/`end` recolored deep-gold → gold (`#8C6D1F` → `#D4AF37`); all six
call sites pick it up with no changes. Structure, border, glow, white
label/icon unchanged.

## Task: #60 slice — gold pill segmented control (#63)

Gold pills on the Ask casting control: transparent fill + gold text when
idle, gold fill + black text when selected, stadium shape. No logic changes.

## Task: #60 slice — frosted-glass form card (#64)

New `GlassCard` (backdrop blur, translucent surface fill, hairline border,
radius 24). The Ask type dropdown + question field sit inside it with
translucent rounded inputs. Adapts to both themes via the color scheme.

## Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green (211 pass)
