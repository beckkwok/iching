# Change Log 2026-09-28

## Task: Fix Android crash (OOM) when generating an explanation

The app was killed by Android's lowmemorykiller when the user tapped
"Get Explanation". An `adb logcat` capture on a Pixel 7 (8 GB) showed the app's
RSS reach ~4.96 GB and the foreground process being killed:

```
18:01:51 [LiteRtLmFfi] Conversation created            # startup openExplanationChat
18:02:13 [LiteRtLmFfi] Conversation closed             # generateExplanation -> openExplanationChat
18:02:13 [LiteRtLmFfi] Engine deleted
18:02:13 Creating engine ... (backend=gpu, maxTokens=4096)   # SECOND engine load
18:02:17 lowmemorykiller: Kill 'com.example.app' (24017) ... to free 4963256kB rss ...
                         reason: min watermark is breached even after kill
18:02:19 Process com.example.app (pid 24017) has died: fg TOP
```

### Root cause
- `LlmService.generateExplanation()` called `openExplanationChat()`, which did
  `closeChat()` → `_registerAndLoad()` → `createModel()` **again**. The model had
  already been loaded at startup, so every explanation loaded a **second**
  native LiteRT-LM engine while the first was being torn down.
- `createModel()` passed no backend, so the plugin used the GPU/WebGPU path,
  which allocates several GB for `.litertlm` models on this device.

### Fix
`lib/services/llm_service.dart` — `openExplanationChat()`:
- **Reuse the loaded `_model`**; only (re)create the conversation
  (`_model!.createChat(...)`). The engine is created at most once per app run.
- Pass **`preferredBackend: PreferredBackend.cpu`** to `createModel()` to avoid
  the memory-heavy GPU/WebGPU path.
- Create the chat with **`isThinking: false`** (for Qwen3 the plugin appends
  `/no_think`) and **`maxOutputTokens: 512`**, so the short 3-5 sentence answer
  does not spend time on a reasoning pass.
- Raised the response timeout from 60 s to **120 s** to accommodate CPU
  inference.

`closeChat()` is unchanged (tears down both chat and model) and is only used by
the "remove model file" flow.

### Verification
- `flutter analyze` — 3 pre-existing info lints (unrelated)
- `flutter test` — 190 tests pass
- **On-device (Pixel 7, arm64, release build)**: after the fix, "Get
  Explanation" returned a real interpretation and the app no longer crashed.
  Log confirmed the CPU/XNNPACK path and no lowmemorykiller kill.

### Diagnostic notes
- The Pixel's `/data` was 100% full during investigation; ADB over USB dropped
  during large APK transfers, so installs were done via `adb tcpip 5555`
  (ADB over Wi-Fi).
