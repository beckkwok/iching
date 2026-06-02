# Local LLM Integration Research

Date: 2026-06-01
Goal: Find a Flutter-compatible way to run a local LLM (Gemma) fully offline for the I-Ching app.

---

## 1. Top Recommendation: `flutter_gemma`

**Package:** [`flutter_gemma`](https://pub.dev/packages/flutter_gemma) v0.16.3  
**Repository:** https://github.com/DenisovAV/flutter_gemma  
**SDK constraint:** Dart >=3.6.0, Flutter >=3.24.0 ✅ (we're on 3.11.5)

### Why it's the best choice

- **Purpose-built for Flutter** — native Dart/Flutter plugin, no bridging frameworks
- **Gemma-native** — first-class support for Google's Gemma model family (as required by spec)
- **100% offline** — models run locally on-device, no internet required after model download
- **Cross-platform** — Android, iOS, Web, Windows, macOS, Linux
- **Multi-model support** — not just Gemma: also Qwen, DeepSeek, Phi-4, SmolLM
- **GPU acceleration** — LiteRT-LM backend with Metal (macOS/iOS), CUDA (desktop), GPU (Android)
- **Mature & active** — 88 versions published, very active maintenance
- **Our SDK fits** — requires Dart >=3.6.0, Flutter >=3.24.0; we're on 3.11.5 ✅

### Supported Models & Sizes

| Model | Size | Best For |
|-------|------|----------|
| **Gemma 3 270M** | ~0.3 GB | Ultra-light, fine-tuning |
| **Gemma 3 1B** | ~0.5 GB | Balanced text generation ✅ *recommended* |
| **Gemma 4 E2B** | ~2.4 GB | Next-gen multimodal |
| **Qwen3 0.6B** | ~586 MB | Compact multilingual |
| **DeepSeek R1 1.5B** | ~1.7 GB | Reasoning |
| **Phi-4 Mini** | ~3.9 GB | Advanced reasoning |
| **SmolLM 135M** | ~135 MB | Ultra-compact (English only) |
| **FunctionGemma 270M** | ~284 MB | Function calling |

### Model File Formats

| Format | Android | iOS | Web | Desktop |
|--------|:-------:|:---:|:---:|:-------:|
| `.task` | ✅ | ✅ | ✅ | ❌ |
| `.litertlm` | ✅ | ✅ | ❌ | ✅ |
| `.bin` / `.tflite` | ✅ | ✅ | ✅ | ✅ (embeddings only) |

### Key Features We Would Use

- Text generation inference (core need)
- Chat templating (built-in for `.task` and `.litertlm` formats)
- Stop generation (user can cancel responses)
- GPU acceleration on supported platforms
- Function calling (future: trigger gua generation via function)
- LoRA fine-tuning (future: custom I-Ching personality)
- RAG (future: retrieve relevant hexagram teachings)

### Estimated Model Download Size

For a mobile I-Ching app, **Gemma 3 1B** at ~500 MB is a reasonable download. The model is downloaded once from HuggingFace and cached locally. After that, no internet is needed.

### Usage Example (from docs)

```dart
import 'package:flutter_gemma/flutter_gemma.dart';

// 1. Initialize
await FlutterGemma.init();

// 2. Install a model (one-time download)
await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
  .fromNetwork('https://huggingface.co/...').install();

// 3. Open a chat session
final chat = await FlutterGemma.openChat(
  modelType: ModelType.gemmaIt,
  systemInstruction: 'You are an I-Ching consultant...',
);

// 4. Send prompt and get response
final response = await chat.send('I feel uncertain about my path.');
print(response.text);

// 5. Clean up
chat.close();
```

---

## 2. Alternative: `tflite_flutter`

**Package:** [`tflite_flutter`](https://pub.dev/packages/tflite_flutter) v0.12.1

- Runs TensorFlow Lite models on-device
- Supports Android, iOS, desktop
- **Limitation:** TF Lite is a general inference framework, not an LLM runtime. Running Gemma via TFLite requires converting the model to TFLite format and handling tokenization manually.
- Much lower-level API — you'd need to implement:
  - Tokenizer (SentencePiece)
  - KV-cache management
  - Sampling logic (top-k, top-p, temperature)
  - Chat template formatting
- **Verdict:** Too low-level for our needs. `flutter_gemma` handles all of this.

---

## 3. Alternative: `google_mlkit` (ML Kit)

- Google's on-device ML SDK for Flutter
- Supports translation, text recognition, barcode scanning, etc.
- **Does NOT support LLM inference or text generation**
- **Verdict:** Not suitable.

---

## 4. Alternative: `llama.cpp` via FFI

- No existing Flutter/Dart package wraps `llama.cpp`
- Would require writing Dart FFI bindings to the C++ library
- Significant development effort
- **Verdict:** Impractical for this project.

---

## 5. Alternative: Ollama (not fully local)

- Requires a running Ollama server process
- On mobile, this isn't feasible
- Requires network calls to localhost (breaks the "no internet" privacy requirement)
- **Verdict:** Not suitable.

---

## 6. Alternative: MediaPipe LLM Inference

- Google's MediaPipe has LLM inference tasks (used internally by `flutter_gemma`)
- But there's no dedicated Flutter plugin — `flutter_gemma` wraps it
- **Verdict:** `flutter_gemma` already uses this under the hood.

---

## Decision

**Use `flutter_gemma` v0.16.3** as the local LLM runtime.

### Recommended Model: Gemma 3 1B (~500 MB)

- Small enough for mobile download
- Multilingual (important for Chinese I-Ching content)
- Good balance of quality and size
- Supported by flutter_gemma's `ModelType.gemmaIt`

### Integration Plan

| Step | Description |
|------|-------------|
| 1 | Add `flutter_gemma` dependency to pubspec.yaml |
| 2 | Call `FlutterGemma.init()` at app startup |
| 3 | Download Gemma 3 1B model on first launch (progress UI) |
| 4 | Initialize a chat session with system instruction for I-Ching consultancy |
| 5 | Replace the placeholder `_generateResponse()` with real LLM inference |
| 6 | Handle GPU/CPU backend selection, stop generation, error states |

### Privacy

- Model is downloaded once from HuggingFace (user consent on first launch)
- After download, **zero network calls** — all inference is on-device
- Fulfills the spec's "no internet to protect user privacy" requirement

---

## Files Consulted

- https://pub.dev/packages/flutter_gemma
- https://github.com/DenisovAV/flutter_gemma
- https://pub.dev/packages/tflite_flutter
- https://pub.dev/packages/google_mlkit_translation
