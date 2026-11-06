import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/agent_memory.dart';

AgentMemory _memory({
  String feeling = '',
  Map<String, String> feelings = const {},
  List<String> facts = const [],
  List<String> preferences = const [],
}) =>
    AgentMemory(
      feeling: feeling,
      feelings: feelings,
      facts: facts,
      preferences: preferences,
      updatedAt: DateTime(2026, 11, 6),
    );

void main() {
  test('approximateTokens grows with the profile', () {
    final small = _memory(feeling: 'calm');
    final large = _memory(feeling: List.filled(4000, 'a').join());

    expect(small.approximateTokens, lessThan(AgentMemory.maxApproximateTokens));
    expect(
      large.approximateTokens,
      greaterThan(AgentMemory.maxApproximateTokens),
    );
  });

  test('toSummaryText includes feelings, facts and preferences', () {
    final memory = _memory(
      feeling: 'calm',
      feelings: {'career': 'anxious'},
      facts: ['job change'],
      preferences: ['stability'],
    );

    expect(memory.toSummaryText, contains('career: anxious'));
    expect(memory.toSummaryText, contains('job change'));
    expect(memory.toSummaryText, contains('stability'));
  });
}
