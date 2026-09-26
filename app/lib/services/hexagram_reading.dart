import '../models/hexagram_content.dart';
import '../models/question_type.dart';
import '../models/yao_line_type.dart';

/// Pure helpers for reading a hexagram relative to a cast and the user's
/// question. Used by the cast result screen.
class HexagramReading {
  HexagramReading._();

  /// True for the "modern vernacular / general" interpretation
  /// (現代白話／通解).
  static bool isModern(Interpretation interpretation) =>
      interpretation.commentator.contains('白話') ||
      interpretation.commentator.contains('通解');

  /// The first modern/general interpretation in [interpretations], or null.
  static Interpretation? modern(List<Interpretation> interpretations) {
    for (final interpretation in interpretations) {
      if (isModern(interpretation)) return interpretation;
    }
    return null;
  }

  /// Maps a [QuestionType] to its 生活與占事常見象徵 key.
  static String? lifeKeyForQuestionType(QuestionType? type) => switch (type) {
    QuestionType.careerAchievement => '事業地位',
    QuestionType.intellectualMoralCultivation => '學問修養',
    QuestionType.timing => '時機',
    QuestionType.attitude => '態度',
    null => null,
  };

  /// The 爻位 name (e.g. 初九, 九二, 上六) for the line at [index]
  /// (0 = bottom 初爻, 5 = top 上爻).
  static String linePositionLabel(int index, bool isYang) {
    final numeral = isYang ? '九' : '六';
    const positions = ['初', '二', '三', '四', '五', '上'];
    if (index == 0) return '初$numeral';
    if (index == 5) return '上$numeral';
    return '$numeral${positions[index]}';
  }

  /// The 爻位 names of the changing (老陰/老陽) lines in [lineTypes].
  static Set<String> changingPositions(List<YaoLineType> lineTypes) {
    if (lineTypes.length != 6) return const {};
    final result = <String>{};
    for (var i = 0; i < 6; i++) {
      final type = lineTypes[i];
      if (type.isChanging) result.add(linePositionLabel(i, type.isYang));
    }
    return result;
  }
}
