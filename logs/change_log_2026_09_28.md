# Change Log 2026-09-28

## Task: Fix Android crash (OOM) when generating an explanation

The app was killed by Android's lowmemorykiller when the user tapped
"Get Explanation". An `adb logcat` capture on a Pixel 7 (8 GB) showed the app's
RSS reach ~4.96 GB and the foreground process being killed:

```
18:01:51 [LiteRtLmFfi] Conversation created            # startup openExplanationChat
18:02:13 [LiteRtLmFfi] Conversation closed             # generateExplanation -> openExplanationChat
18:02:13 [LiteRtLmFfi] Engine deleted
18:02:13 Creating engine ... (backend=gpu, maxTokens=4096)   # second engine load
18:02:17 lowmemorykiller: Kill 'com.example.app' (24017) ... to free 4963256kB rss ...
                         reason: min watermark is breached even after kill
18:02:19 Process com.example.app (pid 24017) has died: fg TOP
```

### Root cause
- `LlmService.generateExplanation()` called `openExplanationChat()`, which did
  `closeChat()` → `_registerAndLoad()` → `createModel()` again. The model had
  already been loaded at startup, so every explanation loaded a **second**
  native LiteRT-LM engine while the first was being torn down.
- `createModel()` passed no backend, so the plugin chose the GPU/WebGPU path,
  which allocates several GB for `.litertlm` models on this device.

### Fix
`lib/services/llm_service.dart` — `openExplanationChat()`:
- Reuse the already-loaded `_model`; only (re)create the conversation
  (`_model!.createChat(...)`). The engine is created at most once per app run.
- Pass `preferredBackend: PreferredBackend.cpu` to `createModel()` to avoid the
  memory-heavy GPU/WebGPU path.

`closeChat()` is unchanged (still tears down both chat and model) and is only
used by the "remove model file" flow.

### Verification
- `flutter analyze` — 3 pre-existing info lints (unrelated)
- `flutter test` — 190 tests pass
- Device verification (Pixel 7): **blocked** — the phone's `/data` is 100% full
  (1.0 GB free) and ADB drops offline during the 125 MB APK transfer/install.
  To be re-run after the device is freed up.
