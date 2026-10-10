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
