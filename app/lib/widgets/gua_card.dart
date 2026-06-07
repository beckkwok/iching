import 'package:flutter/material.dart';
import '../models/gua.dart';

/// Renders the 6-line yao (爻) pattern for a hexagram.
///
/// Each line is either solid (yang ━━━) or broken (yin ━ ━).
/// Lines are drawn bottom-to-top, matching traditional I-Ching order.
class GuaCard extends StatelessWidget {
  final Gua gua;

  const GuaCard({super.key, required this.gua});

  @override
  Widget build(BuildContext context) {
    final lines = _hexagramLines(gua);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: gua name and code
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Gua ${gua.guaCode}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    gua.guaName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Hexagram lines (drawn bottom-to-top)
            Center(
              child: SizedBox(
                width: 120,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lines drawn from top (line 6) to bottom (line 1)
                    for (int i = 5; i >= 0; i--)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: _HexagramLine(
                          isSolid: lines[i],
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Chinese description
            Text(
              gua.guaContent,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // English summary
            Text(
              gua.guaSummary,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single hexagram line: solid (━━━) or broken (━ ━).
class _HexagramLine extends StatelessWidget {
  final bool isSolid;
  final Color color;

  const _HexagramLine({
    required this.isSolid,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
      margin: isSolid
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}

// ---------------------------------------------------------------------------
// Hexagram line pattern mapping
// ---------------------------------------------------------------------------

/// Returns the 6-line pattern for a hexagram by parsing trigram info from
/// [gua.guaContent] (e.g. "上卦乾（天），下卦乾（天）").
///
/// Each element is `true` for a solid (yang) line or `false` for a broken
/// (yin) line. Index 0 = bottom line (line 1), index 5 = top line (line 6).
List<bool> _hexagramLines(Gua gua) {
  // The 8 trigram line patterns (bottom to top within each trigram).
  const trigramMap = <String, List<bool>>{
    '乾': [true, true, true],   // ☰ Qián
    '兑': [false, true, true],  // ☱ Duì
    '离': [true, false, true],  // ☲ Lí
    '震': [false, false, true], // ☳ Zhèn
    '巽': [true, true, false],  // ☴ Xùn
    '坎': [false, true, false], // ☵ Kǎn
    '艮': [true, false, false], // ☶ Gèn
    '坤': [false, false, false],// ☷ Kūn
  };

  // Parse "上卦XXX（Y），下卦XXX（Z）" from guaContent.
  final match = RegExp(r'上卦(\S+).*?下卦(\S+)').firstMatch(gua.guaContent);
  if (match == null) {
    // Fallback: all broken for unknown
    return [false, false, false, false, false, false];
  }

  final upperName = match.group(1)!;
  final lowerName = match.group(2)!;

  final upper = trigramMap[upperName] ?? [false, false, false];
  final lower = trigramMap[lowerName] ?? [false, false, false];

  // Combine: lines 1-3 = lower, lines 4-6 = upper
  return [...lower, ...upper];
}
