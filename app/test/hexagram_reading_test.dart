import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/hexagram_content.dart';
import 'package:app/models/question_type.dart';
import 'package:app/models/yao_line_type.dart';
import 'package:app/services/hexagram_reading.dart';

void main() {
  group('lifeKeyForQuestionType', () {
    test('maps each question type to its life-symbol key', () {
      expect(
        HexagramReading.lifeKeyForQuestionType(QuestionType.careerAchievement),
        '事業地位',
      );
      expect(
        HexagramReading.lifeKeyForQuestionType(
          QuestionType.intellectualMoralCultivation,
        ),
        '學問修養',
      );
      expect(
        HexagramReading.lifeKeyForQuestionType(QuestionType.timing),
        '時機',
      );
      expect(
        HexagramReading.lifeKeyForQuestionType(QuestionType.attitude),
        '態度',
      );
      expect(HexagramReading.lifeKeyForQuestionType(null), isNull);
    });
  });

  group('linePositionLabel', () {
    test('names 九/六 lines by position', () {
      expect(HexagramReading.linePositionLabel(0, true), '初九');
      expect(HexagramReading.linePositionLabel(0, false), '初六');
      expect(HexagramReading.linePositionLabel(1, true), '九二');
      expect(HexagramReading.linePositionLabel(4, false), '六五');
      expect(HexagramReading.linePositionLabel(5, true), '上九');
    });
  });

  group('changingPositions', () {
    test('returns the 爻位 of 老陰/老陽 lines', () {
      const types = [
        YaoLineType.oldYang, // 初九
        YaoLineType.youngYin, // 六二
        YaoLineType.youngYang, // 九三
        YaoLineType.oldYin, // 六四
        YaoLineType.youngYang, // 九五
        YaoLineType.youngYin, // 上六
      ];
      expect(HexagramReading.changingPositions(types), {'初九', '六四'});
    });

    test('returns empty for a cast that is not six lines', () {
      expect(HexagramReading.changingPositions(const []), isEmpty);
    });
  });

  group('isModern / modern', () {
    const modern = Interpretation(
      commentator: '現代白話／通解（綜合）',
      judgmentInterpretation: '',
      lineInterpretations: {},
    );
    const other = Interpretation(
      commentator: '程頤（伊川易傳）',
      judgmentInterpretation: '',
      lineInterpretations: {},
    );

    test('detects the 白話/通解 interpretation', () {
      expect(HexagramReading.isModern(modern), isTrue);
      expect(HexagramReading.isModern(other), isFalse);
    });

    test('finds the first modern interpretation', () {
      expect(HexagramReading.modern([other, modern]), modern);
      expect(HexagramReading.modern([other]), isNull);
    });
  });
}
