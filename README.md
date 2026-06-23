# 🀄 I-Ching Consultant

A privacy-first, offline I-Ching consultation app powered by local LLM inference.  
Built with **Flutter**, **SQLite**, and **Gemma / Qwen** on-device models — no internet required.

> *"Provide emotional support to those at a crossroads. Encourage reflection without judgment."*

---

## ✨ Features

### ✅ Implemented
- **Chat-based consultation** — type your thoughts, receive I-Ching guidance
- **I-Ching (Gua) generation** — random casting or detection of gua by name/number in your text
- **Local LLM integration** — runs Qwen3 0.6B (or other Gemma-compatible models) entirely on-device using `flutter_gemma`
- **Function calling** — LLM can request gua generation via a `generate_gua` tool, and the response incorporates the gua context
- **Conversation history** — all chats persisted in SQLite; browse past sessions
- **Auto-title** — conversations are automatically named by date-time
- **Context compression** — proactive LLM summarization to stay within token limits
- **Cross-platform** — runs on Android, Windows, macOS, Linux, and Web

### 🚧 Planned
- [ ] Gua image / visual representation
- [ ] Enriched gua content with full classical texts
- [ ] Delete conversation history (long-press in history list)
- [ ] Settings screen (privacy notice, model path, model selection, prompt settings, storage management)
- [ ] Privacy validation test suite (no network calls)
- [ ] Android packaging & app store readiness
- [ ] Strategy pattern for gua generation (`SimpleGuaGeneratorStrategy`, etc.)

---

## 🧱 Tech Stack

| Layer        | Technology                              |
|--------------|-----------------------------------------|
| Framework    | [Flutter](https://flutter.dev) 3.44+    |
| Language     | Dart 3.12+                              |
| Database     | SQLite via `sqflite`                    |
| LLM Runtime  | `flutter_gemma` (supports Gemma, Qwen, DeepSeek, Phi-4, etc.) |
| Model        | Qwen3 0.6B (downloaded from HuggingFace at first run) |
| Platform     | Android (primary), Windows, macOS, Linux, Web |

---

## 🏗️ Architecture

```
iching/
├── app/                      # Flutter application
│   ├── lib/
│   │   ├── data/             # Gua data (64 hexagrams)
│   │   ├── models/           # Dart data models
│   │   ├── screens/          # UI screens (chat, history, detail)
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
User Input
    │
    ├─► LLM (local) processes prompt
    │       │
    │       ├─► generate_gua function call ──► GuaGenerator
    │       │                                       │
    │       │                              random cast / detect in text
    │       │                                       │
    │       │                              return gua (1-64)
    │       │
    │       └─► Generates reflective response with gua context
    │
    └─► Saved to SQLite (conversation + messages)
```

### Database Schema

- **Conversations** — id, title, created_at, updated_at, last_gua_id
- **Messages** — id, conversation_id, sender (user/system), content, gua_id, timestamp
- **Gua** — id, code (1-64), name, content, summary, source

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

# Run the appNice,
flutter run
```

> **Note:** On first run, the app will download the LLM model from HuggingFace (~600MB for Qwen3 0.6B).  
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

This app is designed with **privacy as a core principle**:
- All LLM inference runs **locally on-device**
- **No internet connection required** after model download
- All conversations are stored **only in local SQLite**
- No telemetry, no analytics, no external API calls

---

## 📄 License

This project is licensed under the MIT License — see [LICENSE](./LICENSE) for details.
