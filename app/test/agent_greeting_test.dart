import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/l10n/app_localizations.dart';
import 'package:app/models/agent_memory.dart';
import 'package:app/services/agent_greeting.dart';

AgentMemory _memory({
  String feeling = '',
  Map<String, String> feelings = const {},
  List<String> facts = const [],
  List<String> preferences = const [],
}) => AgentMemory(
  feeling: feeling,
  feelings: feelings,
  facts: facts,
  preferences: preferences,
  updatedAt: DateTime(2026, 11, 3),
);

void main() {
  final en = AppLocalizations(const Locale('en'));
  final zh = AppLocalizations(const Locale('zh'));

  test('returns null for empty memory', () {
    expect(buildAgentGreeting(_memory(), en), isNull);
  });

  test('greets with the overall feeling', () {
    final greeting = buildAgentGreeting(
      _memory(feeling: 'hopeful about the new job.'),
      en,
    );

    expect(
      greeting,
      'Welcome back. It sounds like you have been feeling hopeful about the '
      'new job.',
    );
  });

  test('falls back to a per-topic feeling', () {
    final greeting = buildAgentGreeting(
      _memory(feelings: {'Career Achievement': 'anxious. '}),
      en,
    );

    expect(greeting, contains('Welcome back.'));
    expect(greeting, contains('feeling anxious.'));
    expect(greeting, isNot(contains('anxious..')));
  });

  test('falls back to a fact, then a preference', () {
    expect(
      buildAgentGreeting(_memory(facts: ['lives in Hong Kong']), en),
      'Welcome back. I remember: lives in Hong Kong.',
    );
    expect(
      buildAgentGreeting(_memory(preferences: ['values stability']), en),
      'Welcome back. I remember: values stability.',
    );
  });

  test('localizes the greeting (zh)', () {
    final greeting = buildAgentGreeting(_memory(feeling: 'hopeful'), zh);

    expect(greeting, contains('歡迎回來'));
    expect(greeting, contains('hopeful'));
  });

  test('detects when the profile matches the locale script', () {
    expect(
      memoryGreetingMatchesLocale(_memory(feeling: 'hopeful'), en),
      isTrue,
    );
    expect(memoryGreetingMatchesLocale(_memory(feeling: '充滿希望'), zh), isTrue);
    expect(
      memoryGreetingMatchesLocale(_memory(feeling: 'hopeful'), zh),
      isFalse,
    );
    expect(memoryGreetingMatchesLocale(_memory(feeling: '充滿希望'), en), isFalse);
  });
}
