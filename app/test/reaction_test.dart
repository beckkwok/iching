import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/reaction.dart';

void main() {
  test('has the six reactions with unique keys and emoji', () {
    expect(Reaction.values, hasLength(6));
    final keys = Reaction.values.map((r) => r.key).toSet();
    expect(keys, hasLength(Reaction.values.length));
    for (final reaction in Reaction.values) {
      expect(reaction.key, isNotEmpty);
      expect(reaction.emoji, isNotEmpty);
    }
  });

  test('fromKey resolves a reaction key', () {
    expect(Reaction.fromKey('happy'), Reaction.happy);
    expect(Reaction.fromKey('healing'), Reaction.healing);
  });

  test('fromKey returns null for unknown or null keys', () {
    expect(Reaction.fromKey('unknown'), isNull);
    expect(Reaction.fromKey(null), isNull);
  });
}
