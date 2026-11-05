import 'package:flutter_test/flutter_test.dart';

import 'package:app/data/interpreter_catalog.dart';
import 'package:app/services/llm_prompts.dart';

void main() {
  test('catalog keys are unique and every field is filled', () {
    final keys = InterpreterCatalog.all.map((i) => i.key).toList();

    expect(keys.toSet().length, keys.length);
    for (final interpreter in InterpreterCatalog.all) {
      expect(interpreter.key, isNotEmpty);
      expect(interpreter.name, isNotEmpty);
      expect(interpreter.nameZh, isNotEmpty);
      expect(interpreter.description, isNotEmpty);
      expect(interpreter.systemPrompt, isNotEmpty);
    }
  });

  test('default interpreter exists and uses the compassionate prompt', () {
    expect(InterpreterCatalog.byKey(InterpreterCatalog.defaultKey), isNotNull);
    expect(
      InterpreterCatalog.defaultInterpreter.key,
      InterpreterCatalog.defaultKey,
    );
    expect(
      InterpreterCatalog.defaultInterpreter.systemPrompt,
      LlmPrompts.systemPrompt,
    );
  });

  test('byKey handles unknown and null keys', () {
    expect(InterpreterCatalog.byKey(null), isNull);
    expect(InterpreterCatalog.byKey('nope'), isNull);
    expect(InterpreterCatalog.byKey('classical')?.key, 'classical');
  });

  test('displayName switches language', () {
    final interpreter = InterpreterCatalog.byKey('classical')!;

    expect(interpreter.displayName(false), 'Classical Scholar');
    expect(interpreter.displayName(true), '古典學者');
  });

  test('each interpreter has a distinct system prompt', () {
    final prompts = InterpreterCatalog.all.map((i) => i.systemPrompt).toSet();

    expect(prompts.length, InterpreterCatalog.all.length);
  });
}
