import 'package:flutter_test/flutter_test.dart';

import 'package:app/data/trigram_hexagram_data.dart';
import 'package:app/models/trigram_hexagram.dart';

void main() {
  group('TrigramHexagramData', () {
    test('contains all 64 combinations', () {
      expect(TrigramHexagramData.all.length, 64);
    });

    test('every low/high code combination is unique', () {
      final pairs = TrigramHexagramData.all
          .map((e) => '${e.lowCode},${e.highCode}')
          .toSet();
      expect(pairs.length, 64);
    });

    test('low/high codes are within 1..8', () {
      for (final entry in TrigramHexagramData.all) {
        expect(entry.lowCode, inInclusiveRange(1, 8));
        expect(entry.highCode, inInclusiveRange(1, 8));
      }
    });

    test('result codes are unique and cover 1..64', () {
      final codes = TrigramHexagramData.all
          .map((e) => e.resultCode)
          .toList()
        ..sort();
      expect(codes, List.generate(64, (i) => i + 1));
    });

    test('resultCode equals (lowCode - 1) * 8 + highCode', () {
      for (final entry in TrigramHexagramData.all) {
        expect(entry.resultCode, (entry.lowCode - 1) * 8 + entry.highCode,
            reason: '${entry.lowDesc}下 ${entry.highName}上');
      }
    });

    test('linesToCode maps all 8 trigram patterns to codes 1..8', () {
      expect(TrigramHexagramData.linesToCode(false, false, false), 1); // 地
      expect(TrigramHexagramData.linesToCode(false, false, true), 2); // 山
      expect(TrigramHexagramData.linesToCode(false, true, false), 3); // 水
      expect(TrigramHexagramData.linesToCode(false, true, true), 4); // 風
      expect(TrigramHexagramData.linesToCode(true, false, false), 5); // 雷
      expect(TrigramHexagramData.linesToCode(true, false, true), 6); // 火
      expect(TrigramHexagramData.linesToCode(true, true, false), 7); // 澤
      expect(TrigramHexagramData.linesToCode(true, true, true), 8); // 天
    });

    test('linesToCode produces unique codes for unique patterns', () {
      final codes = <int>{};
      for (var i = 0; i < 2; i++) {
        for (var j = 0; j < 2; j++) {
          for (var k = 0; k < 2; k++) {
            codes.add(TrigramHexagramData.linesToCode(i == 1, j == 1, k == 1));
          }
        }
      }
      expect(codes.length, 8);
      expect(codes, {1, 2, 3, 4, 5, 6, 7, 8});
    });

    test('linesToCode output matches all data entries', () {
      for (final entry in TrigramHexagramData.all) {
        final code = TrigramHexagramData.linesToCode(
          // Binary pattern derived from trigram code: code-1 as 3 bits
          ((entry.lowCode - 1) & 4) != 0,
          ((entry.lowCode - 1) & 2) != 0,
          ((entry.lowCode - 1) & 1) != 0,
        );
        expect(code, entry.lowCode, reason: '${entry.lowDesc} trigram');
      }
    });

    test('known combos resolve to correct hexagrams', () {
      expect(TrigramHexagramData.byCodes(8, 8)?.resultName, '乾為天');
      expect(TrigramHexagramData.byCodes(1, 1)?.resultName, '坤為地');
      expect(TrigramHexagramData.byCodes(8, 7)?.resultName, '澤天夬');
      expect(TrigramHexagramData.byCodes(4, 1)?.resultName, '地風升');
      expect(TrigramHexagramData.byCodes(8, 8)?.resultCode, 64);
      expect(TrigramHexagramData.byCodes(1, 1)?.resultCode, 1);
    });

    test('byResultCode returns matching entry', () {
      expect(TrigramHexagramData.byResultCode(64)?.resultName, '乾為天');
      expect(TrigramHexagramData.byResultCode(25)?.resultName, '地風升');
      expect(TrigramHexagramData.byResultCode(1)?.resultName, '坤為地');
      expect(TrigramHexagramData.byResultCode(0), isNull);
      expect(TrigramHexagramData.byResultCode(65), isNull);
    });

    test('byCodes returns null for invalid combo', () {
      expect(TrigramHexagramData.byCodes(9, 1), isNull);
      expect(TrigramHexagramData.byCodes(1, 0), isNull);
    });

    test('model round-trips through toMap/fromMap', () {
      const entry = TrigramHexagram(
        lowCode: 4,
        lowDesc: '風',
        highCode: 1,
        highName: '地',
        resultCode: 25,
        resultName: '地風升',
      );
      final reparsed = TrigramHexagram.fromMap(entry.toMap());
      expect(reparsed, entry);
    });
  });
}
