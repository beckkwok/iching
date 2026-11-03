# 🀄 I-Ching Consultant

An I-Ching consultation app powered by AI — on-device or a remote LLM provider.  
Built with **Flutter**, **SQLite**, on-device **Gemma / Qwen** models, and optional remote providers; data handling is documented in [ADR 0001](docs/adr/0001-remote-llm-support.md).

> *"Provide emotional support to those at a crossroads. Encourage reflection without judgment."*

---

## ✨ Features

### ✅ Implemented
- **Mobile shell** — portrait-first UI with a `forui` bottom navigation bar (History, Profile, Ask, Browse, Preference) and Rive-animated icons; the header bar was removed
- **Form-based consultation** — pick a question type (Career Achievement, Intellectual and moral cultivation, Timing, Attitude), enter your question, and submit
- **I-Ching (Gua) casting** — six yao lines are cast with the traditional three-coin method (老陰/少陽/少陰/老陽) and resolved into a hexagram
- **One-shot LLM explanation** — a single, token-light call connects the hexagram context to your question (no multi-turn chat, so it stays within the model's context window)
- **Language preference** — choose English or Chinese (中文); the choice localizes the whole UI and is injected into the explanation prompt
- **Editable system prompt** — view and customize the LLM instruction in Settings
- **Hexagram browser** — browse all 64 hexagrams in a grid; tap any card for the full detail view (卦辭, 彖傳, 大象傳, 爻辭, 象徵意義, 不同人解讀)
- **LLM integration** — runs a selectable on-device model via `flutter_gemma` (6 models available, e.g. Gemma 4, DeepSeek R1, Qwen3); remote providers are supported alongside on-device inference ([ADR 0001](docs/adr/0001-remote-llm-support.md))
- **Default model** — Qwen3-0.6B is auto-downloaded on first run (no selection); the model grid is a development-only option. Internet is used to fetch the on-device model; when a remote provider is configured, the question and hexagram context are sent to that provider ([ADR 0001](docs/adr/0001-remote-llm-support.md)).
- **Cross-platform** — runs on Android, Windows, macOS, Linux, and Web

### 🚧 Planned
- [ ] Gua image / visual representation
- [ ] Enriched gua content with full classical texts
- [ ] Load hexagrams directly from JSON assets (remove the `gua` DB table)
- [ ] Privacy validation test suite (guard against unintended network calls)
- [ ] Android packaging & app store readiness

---

## 🧱 Tech Stack

| Layer        | Technology                              |
|--------------|-----------------------------------------|
| Framework    | [Flutter](https://flutter.dev) 3.44+    |
| Language     | Dart 3.12+                              |
| Database     | SQLite via `sqflite` (settings) + JSON asset files (hexagrams) |
| LLM Runtime  | `flutter_gemma` + `flutter_gemma_litertlm` |
| Model        | Qwen3-0.6B by default (auto-downloaded on first run); selection available in development |
| Platform     | Android (primary), Windows, macOS, Linux, Web |

---

## 🏗️ Architecture

```
iching/
├── app/                      # Flutter application
│   ├── lib/
│   │   ├── data/             # Gua data (64 hexagrams)
│   │   ├── models/           # Dart data models
│   │   ├── screens/          # UI screens (question form, cast result, explanation, hexagram browser/detail)
│   │   ├── services/         # Business logic (DB, LLM, gua generator)
│   │   ├── widgets/          # Reusable UI components
│   │   └── main.dart         # App entry point
│   ├── test/                 # Unit & widget tests
│   ├── android/              # Android platform config
│   ├── ios/                  # iOS platform config
│   ├── windows/              # Windows platform config
│   ├── macos/                # macOS platform config
│   ├── linux/                # Linux platform config
│   └── web/                  # Web platform config
├── logs/                     # Change logs
├── models/                   # Downloaded model files
├── scripts/                  # Build & utility scripts
├── tools/                    # Development tools
├── spec.md                   # Full project specification
└── AGENTS.md                 # AI agent development guidelines
```

### Data Flow

```
Question Form
    │  (category + question)
    ▼
GuaGenerator (casts 6 yao lines via three-coin method)
    │  (resolve hexagram from trigram mapping)
    ▼
Cast Result (卦象 + per-line 老陰/少陽/少陰/老陽)
    │  (tap "Get Explanation")
    ▼
LLM (on-device or remote) — one-shot call
    │  (hexagram context + question + language preference)
    ▼
Explanation (解讀)
```

### Database Schema

The database stores **only settings** (model selection, language preference,
custom system prompt). Hexagrams are loaded directly from the bundled JSON
assets (`assets/hexagrams/gua_<n>.json`) via `HexagramLoader` — there is no
`gua` table.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.44+
- Android Studio or VS Code with Flutter extension
- Android emulator or physical device (for Android builds)

### Setup

```bash
# Clone the repository
git clone <repo-url>
cd iching

# Install Flutter dependencies
cd app
flutter pub get

# Create an Android emulator (if not already created)
flutter emulators --create --name pixel_6

# Launch the emulator
flutter emulators --launch pixel_6

# Run the app
flutter run
```

> **Note:** On first run, the app asks you to select and download an LLM model from HuggingFace
> (sizes range from ~0.5 GB to ~3.6 GB depending on the model).  
> Ensure you have sufficient storage and a stable connection for the download.

### Running Tests

```bash
cd app
flutter test
```

### Running on Android

```bash
# List available devices
flutter devices

# Run on a specific device
flutter run -d emulator-5554

# Or install APK directly
flutter install
```

---

## 📝 Development

### Code Style

- Follow [Dart effective style](https://dart.dev/effective-dart/style)
- One function per prompt (see `AGENTS.md`)
- Each function must have corresponding unit tests
- Log all changes in `logs/change_log_yyyy_mm_dd.md`

### Project Guidelines

See [AGENTS.md](./AGENTS.md) for the full set of development rules.

### Spec

See [spec.md](./spec.md) for the detailed project specification and task tracking.

---

## 🔒 Privacy

The app supports **on-device inference and remote LLM providers** (see [ADR 0001](docs/adr/0001-remote-llm-support.md)). How your data is handled:
- On-device inference (`flutter_gemma`) keeps everything on your device (internet only to download the model).
- When a remote provider is configured, the prompt — your question plus the hexagram context — is sent to that provider to generate the explanation.
- Settings and consultations are stored **only in local SQLite**.
- No telemetry or analytics beyond the configured provider's standard traffic; no other external API calls.

---

## 📄 License

This project is licensed under the MIT License — see [LICENSE](./LICENSE) for details.
