import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:app/services/firebase_ai_backend.dart';
import 'package:app/services/firebase_bootstrap.dart';
import 'package:app/services/gua_generator.dart';

/// MANUAL smoke test — **not** run by `flutter test` or CI.
///
/// It makes a real Firebase AI Logic (Gemini) call, so it needs:
/// - a device/emulator,
/// - `app/firebase.local.json` (git-ignored) with the restricted API key,
/// - a registered App Check debug token (set `FIREBASE_APPCHECK_DEBUG_TOKEN`).
///
/// Run manually:
/// ```
/// flutter test -d emulator-5554 \
///   --dart-define-from-file=firebase.local.json \
///   integration_test/manual/firebase_ai_smoke_test.dart
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Firebase AI Logic returns a clean explanation', (tester) async {
    final ready = await initializeFirebase();
    expect(ready, isTrue, reason: 'Firebase + App Check must initialize');

    final generator = GuaGenerator();
    final result = await generator.generateRandom();
    final backend = FirebaseAiBackend(guaGenerator: generator);

    final text = await backend.generateExplanation(
      question: 'Should I take the new job?',
      questionTypeLabel: 'Career Achievement',
      result: result,
    );

    expect(text, isNot('(The explanation could not be generated.)'));
    expect(text.trim(), isNotEmpty);
    expect(text, isNot(contains('<|channel>')));
    expect(text, isNot(contains('<|endoftext|>')));
  });
}
