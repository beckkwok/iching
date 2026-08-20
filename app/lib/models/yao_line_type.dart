/// The four possible yao (爻) line types from a traditional I-Ching cast.
///
/// Casting each line uses three coins (each 2 = yin/tails or 3 = yang/heads);
/// the sum is 6, 7, 8, or 9:
/// - 6 = 老陰 (old yin)   — broken, changing
/// - 7 = 少陽 (young yang) — solid, stable
/// - 8 = 少陰 (young yin)  — broken, stable
/// - 9 = 老陽 (old yang)   — solid, changing
enum YaoLineType {
  oldYin(6, '老陰', isYang: false, isChanging: true),
  youngYang(7, '少陽', isYang: true, isChanging: false),
  youngYin(8, '少陰', isYang: false, isChanging: false),
  oldYang(9, '老陽', isYang: true, isChanging: true);

  /// The cast value (6, 7, 8, or 9).
  final int value;

  /// Display label (老陰 / 少陽 / 少陰 / 老陽).
  final String label;

  /// True for yang (solid) lines, false for yin (broken) lines.
  final bool isYang;

  /// True for changing (moving) lines — 老陰 / 老陽.
  final bool isChanging;

  const YaoLineType(this.value, this.label,
      {required this.isYang, required this.isChanging});

  /// Map a three-coin sum (6–9) to the matching [YaoLineType].
  static YaoLineType fromValue(int value) {
    return switch (value) {
      6 => YaoLineType.oldYin,
      7 => YaoLineType.youngYang,
      8 => YaoLineType.youngYin,
      _ => YaoLineType.oldYang,
    };
  }
}
