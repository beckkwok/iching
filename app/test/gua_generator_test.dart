import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/data/trigram_hexagram_data.dart';
import 'package:app/models/yao_line_type.dart';
import 'package:app/services/gua_generator.dart';
import 'package:app/services/hexagram_loader.dart';

/// Trigram char by 1-based code: 1=坤, 2=艮, 3=坎, 4=巽, 5=震, 6=離, 7=兌, 8=乾.
const _trigramChars = ['坤', '艮', '坎', '巽', '震', '離', '兌', '乾'];

/// Builds the list of all 64 (low, high) trigram combos, reordered so
/// gua_code 1 = 乾為天 (8,8) and gua_code 2 = 坤為地 (1,1) — matching the
/// King Wen convention used by the findInText tests.
List<(int, int)> _allCombos() {
  final combos = <(int, int)>[
    for (var low = 1; low <= 8; low++)
      for (var high = 1; high <= 8; high++) (low, high),
  ];
  final idx88 = combos.indexWhere((c) => c.$1 == 8 && c.$2 == 8);
  final tmp = combos[0];
  combos[0] = combos[idx88];
  combos[idx88] = tmp;
  final idx11 = combos.indexWhere((c) => c.$1 == 1 && c.$2 == 1);
  final tmp2 = combos[1];
  combos[1] = combos[idx11];
  combos[idx11] = tmp2;
  return combos;
}

/// Minimal valid hexagram JSON for [code]. Each gua gets a unique trigram
/// combination (via [TrigramHexagramData]) so cast resolution is deterministic.
///
/// `guaName` (卦名) is the mapping's classical resultName (e.g. "乾為天"),
/// matching how the real `gua_<n>.json` files are authored.
String fixtureJson(int code) {
  final (low, high) = _allCombos()[code - 1];
  final entry = TrigramHexagramData.byCodes(low, high)!;
  final symbol =
      '䷀（下${_trigramChars[low - 1]}上${_trigramChars[high - 1]}）';
  return jsonEncode({
    '卦名': entry.resultName,
    '卦序': code,
    '卦象': symbol,
    '卦辭': '卦辭 $code',
    '彖傳': '彖傳 $code',
    '大象傳': '大象傳 $code',
    '爻辭': [],
    '象徵意義': {
      '基本卦象': {'卦體': '下乾上乾', '自然取象': '天', '說明': '說明'},
      '主要象徵': [],
      '生活與占事常見象徵': {},
      '總結': '總結 $code',
    },
    '不同人解讀': [],
    '備註': '',
  });
}

void main() {
  late GuaGenerator generator;

  setUp(() {
    generator = GuaGenerator(HexagramLoader((code) async => fixtureJson(code)));
  });

  group('GuaGenerator', () {
    test('generateRandom returns 6 cast lines with systemGenerated method',
        () async {
      final result = await generator.generateRandom();

      expect(result, isA<GenerationResult>());
      expect(result.method, GeneratorMethod.systemGenerated);
      expect(result.hasCast, isTrue);
      expect(result.lines.length, 6);
      // Cast resolves to a gua in the DB.
      expect(result.gua.guaCode, inInclusiveRange(1, 64));
    });

    test('generateRandom casts 6 line types from the four yao types',
        () async {
      final result = await generator.generateRandom();

      expect(result.lineTypes.length, 6);
      for (final t in result.lineTypes) {
        expect(t.value, inInclusiveRange(6, 9));
        expect(
          const ['老陰', '少陽', '少陰', '老陽'],
          contains(t.label),
        );
      }
      // Boolean lines must agree with the line types.
      for (var i = 0; i < 6; i++) {
        expect(result.lines[i], result.lineTypes[i].isYang);
      }
    });

    test('resolveCast with lineTypes preserves them on the result', () async {
      final lines = [true, false, true, false, true, false];
      final types = [
        YaoLineType.oldYang,
        YaoLineType.youngYin,
        YaoLineType.youngYang,
        YaoLineType.oldYin,
        YaoLineType.youngYang,
        YaoLineType.youngYin,
      ];
      final result = await generator.resolveCast(lines, lineTypes: types);

      expect(result.lineTypes, types);
      expect(result.lineTypeLabels,
          ['老陽', '少陰', '少陽', '老陰', '少陽', '少陰']);
    });

    test('generateRandom resolves the gua matching the cast lines', () async {
      final result = await generator.generateRandom();

      // The resolved gua's 卦象 must match the cast lines exactly.
      final resolvedLines =
          TrigramHexagramData.linesFromSymbol(result.gua.content!.guaSymbol);
      expect(resolvedLines, result.lines);
    });

    test('generateRandom lines are consistent with the mapping table',
        () async {
      final result = await generator.generateRandom();

      final lowerCode = TrigramHexagramData.linesToCode(
          result.lines[0], result.lines[1], result.lines[2]);
      final upperCode = TrigramHexagramData.linesToCode(
          result.lines[3], result.lines[4], result.lines[5]);
      final entry = TrigramHexagramData.byCodes(lowerCode, upperCode);
      expect(entry, isNotNull);
      // The mapping's resultName matches the gua's stored name.
      final guaName = result.gua.content?.guaName ?? result.gua.guaName;
      expect(entry!.resultName, guaName);
    });

    test('generateRandom produces different results', () async {
      final results = <int>{};
      for (int i = 0; i < 20; i++) {
        final result = await generator.generateRandom();
        results.add(result.gua.guaCode);
      }
      expect(results.length, greaterThan(1));
    });

    test('a fixed cast of 6 yang lines resolves to 乾為天', () async {
      // lower 天(8) + upper 天(8) → 乾為天.
      final lines = [true, true, true, true, true, true];
      final result = await generator.resolveCast(lines);
      expect(result.gua.guaCode, 1, reason: '乾為天 should be gua 1');
      expect(result.lines, lines);
    });

    test('a fixed cast of 6 yin lines resolves to 坤為地', () async {
      // lower 地(1) + upper 地(1) → 坤為地.
      final lines = [false, false, false, false, false, false];
      final result = await generator.resolveCast(lines);
      expect(result.gua.guaCode, 2, reason: '坤為地 should be gua 2');
      expect(result.lines, lines);
    });

    test('resolveCast rejects a cast that is not 6 lines', () async {
      expect(() => generator.resolveCast([true, false]),
          throwsA(isA<ArgumentError>()));
    });

    test('findInText detects gua by number with manual method',
        () async {
      final result = await generator.findInText('Tell me about gua 23');
      expect(result, isNotNull);
      expect(result!.gua.guaCode, 23);
      expect(result.method, GeneratorMethod.manual);
    });

    test('findInText detects gua by hexagram keyword', () async {
      final result = await generator.findInText('What does hexagram 1 mean?');
      expect(result, isNotNull);
      expect(result!.gua.guaCode, 1);
    });

    test('findInText detects gua by classical name', () async {
      final result = await generator.findInText('我想知道乾為天卦的含義');
      expect(result, isNotNull);
      expect(result!.gua.guaCode, 1);
    });

    test('findInText returns null for unrelated text', () async {
      final result = await generator.findInText(
        'I feel uncertain about my career path',
      );
      expect(result, isNull);
    });

    test('formatContext includes method header and gua details', () async {
      final result = await generator.generateRandom();
      final context = generator.formatContext(result);

      expect(context, contains('Hexagram'));
      expect(context, contains('gua code ${result.gua.guaCode}'));
      expect(context, contains(result.gua.guaName));
      expect(context, contains('卦辭'));
      expect(context, contains('象徵總結'));
    });

    test('formatContext includes the cast lines for system casts', () async {
      final lines = [true, false, true, false, true, false];
      final result = await generator.resolveCast(lines);
      final context = generator.formatContext(result);

      expect(context, contains('Cast lines (bottom to top)'));
      expect(context, contains('yang, yin, yang, yin, yang, yin'));
    });

    test('formatContext omits cast lines for manual results', () async {
      final gua = (await generator.generateRandom()).gua;
      final manual = generator.formatContext(
          GenerationResult(gua: gua, method: GeneratorMethod.manual));

      expect(manual, isNot(contains('Cast lines')));
    });

    test('formatContext has different headers for different methods',
        () async {
      final gua = (await generator.generateRandom()).gua;

      final manual = generator.formatContext(
          GenerationResult(gua: gua, method: GeneratorMethod.manual));
      final systemGenerated = generator.formatContext(
          GenerationResult(gua: gua, method: GeneratorMethod.systemGenerated));

      expect(manual, isNot(equals(systemGenerated)));
      expect(manual, contains('specifically asked'));
      expect(systemGenerated, contains('at the user\'s request'));
    });

    test('findInText detects gua by classical name 坤為地', () async {
      final result = await generator.findInText('坤為地卦怎麼說？');
      expect(result, isNotNull);
      expect(result!.gua.guaCode, 2);
    });

    test('findInText detects gua number with Chinese 卦 prefix', () async {
      final result = await generator.findInText('卦 42');
      expect(result, isNotNull);
      expect(result!.gua.guaCode, 42);
    });
  });
}
