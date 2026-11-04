import 'package:flutter/material.dart';

import 'package:app/models/interpreter.dart';
import 'package:app/services/llm_prompts.dart';

/// Built-in interpreters (issue #22).
///
/// The selected key is stored in the `settings` table under [settingsKey]. The
/// default interpreter uses the same compassionate prompt as the rest of the
/// app; the others offer different "voices" for the same cast.
class InterpreterCatalog {
  InterpreterCatalog._();

  /// Settings key for the selected interpreter.
  static const String settingsKey = 'selected_interpreter';

  /// Key of the interpreter selected by default.
  static const String defaultKey = 'compassionate';

  static const List<Interpreter> all = [
    Interpreter(
      key: 'compassionate',
      name: 'Compassionate Counselor',
      nameZh: '慈悲顧問',
      description: 'Warm, reflective guidance',
      avatar: Icons.self_improvement,
      systemPrompt: LlmPrompts.systemPrompt,
    ),
    Interpreter(
      key: 'classical',
      name: 'Classical Scholar',
      nameZh: '古典學者',
      description: 'Rooted in the classical texts',
      avatar: Icons.menu_book,
      systemPrompt:
          'You are a classical I-Ching scholar. Interpret the hexagram through '
          'the classical texts (卦辭, 彖傳, 大象傳, 爻辭) and traditional '
          'imagery.\n\n'
          'Connect the hexagram to the user\'s question with precise references '
          'to the texts, but keep the language accessible. Never predict good '
          'or bad fortune; frame the reading as an invitation for reflection. '
          'Keep responses to 3-5 sentences.',
    ),
    Interpreter(
      key: 'practical',
      name: 'Practical Advisor',
      nameZh: '務實顧問',
      description: 'Grounded, actionable guidance',
      avatar: Icons.lightbulb_outline,
      systemPrompt:
          'You are a grounded, practical advisor. Use the hexagram as a lens '
          'for concrete reflection on the user\'s situation.\n\n'
          'Offer a clear, actionable perspective while staying compassionate '
          'and non-judgmental. Never predict good or bad fortune; frame the '
          'reading as an invitation for reflection. Keep responses to 3-5 '
          'sentences.',
    ),
  ];

  /// The default interpreter.
  static Interpreter get defaultInterpreter => byKey(defaultKey) ?? all.first;

  /// Look up an interpreter by [key], or `null` when unknown.
  static Interpreter? byKey(String? key) {
    if (key == null) return null;
    for (final interpreter in all) {
      if (interpreter.key == key) return interpreter;
    }
    return null;
  }
}
