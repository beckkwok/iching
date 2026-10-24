import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/consultation.dart';
import 'package:app/models/yao_line_type.dart';

Consultation _consultation() => Consultation(
  id: 7,
  question: 'Should I move?',
  questionTypeLabel: 'Timing',
  hexagramCode: 46,
  hexagramName: '地風升',
  hexagramContent: '{"卦名":"地風升","卦序":46}',
  explanation: 'A gentle reflection.',
  lineTypes: const [
    YaoLineType.oldYang,
    YaoLineType.youngYin,
    YaoLineType.youngYang,
    YaoLineType.oldYin,
    YaoLineType.youngYang,
    YaoLineType.youngYin,
  ],
  changedHexagramCode: 12,
  changedHexagramName: '天地否',
  changedHexagramContent: '{"卦名":"天地否","卦序":12}',
  reaction: 'love',
  comment: 'Hopeful.',
  createdAt: DateTime(2026, 9, 23, 10, 30),
);

void main() {
  test('toMap/fromMap round-trip the full record', () {
    final original = _consultation();
    final restored = Consultation.fromMap(original.toMap());

    expect(restored, original);
    expect(restored.lineTypes, original.lineTypes);
    expect(restored.changedHexagramCode, 12);
    expect(restored.changedHexagramName, '天地否');
    expect(restored.changedHexagramContent, '{"卦名":"天地否","卦序":12}');
  });

  test('fromMap defaults the cast fields for legacy rows', () {
    final legacy = Consultation.fromMap({
      'id': 1,
      'question': 'q',
      'hexagram_code': 1,
      'hexagram_name': '乾為天',
      'hexagram_content': '{}',
      'explanation': 'e',
      'created_at': '2026-01-01T00:00:00.000',
    });

    expect(legacy.lineTypes, isEmpty);
    expect(legacy.changedHexagramCode, isNull);
    expect(legacy.changedHexagramName, isNull);
    expect(legacy.changedHexagramContent, isNull);
    expect(legacy.castLines, isEmpty);
    expect(legacy.changedLines, isEmpty);
    expect(legacy.hasChangedHexagram, isFalse);
  });

  test('derives cast and changed lines from the stored line types', () {
    final c = _consultation();

    // oldYang / youngYin / youngYang / oldYin / youngYang / youngYin
    expect(c.castLines, [true, false, true, false, true, false]);
    expect(c.changedLines, [false, false, true, true, true, false]);
    expect(c.hasChangingLines, isTrue);
    expect(c.hasChangedHexagram, isTrue);
  });

  test('fromMap tolerates malformed line_types JSON', () {
    final row = Consultation.fromMap({
      'question': 'q',
      'hexagram_code': 1,
      'hexagram_name': '乾為天',
      'hexagram_content': '{}',
      'explanation': 'e',
      'line_types': 'not-json',
      'created_at': '2026-01-01T00:00:00.000',
    });

    expect(row.lineTypes, isEmpty);
  });
}
