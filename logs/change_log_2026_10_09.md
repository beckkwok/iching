# Change Log 2026-10-09

## Task: #60 slice — gold-forward app theme (#61)

Gold seeds for both Material schemes (`ancientGold`), so the bottom-nav
active tint (`colorScheme.primary` via `_NavIcon`) is gold in both modes.
Forui themes untouched.

## Task: #60 slice — gold GradientButton (#62)

`start`/`end` recolored deep-gold → gold (`#8C6D1F` → `#D4AF37`); all six
call sites pick it up with no changes. Structure, border, glow, white
label/icon unchanged.

## Verification

- `flutter analyze` — clean (3 pre-existing info lints)
- `flutter test` — green
