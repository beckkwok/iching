import 'package:flutter/material.dart';
import '../data/trigram_hexagram_data.dart';
import '../models/gua.dart';
import '../screens/hexagram_detail_screen.dart';

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => HexagramDetailScreen(gua: gua)),
            );
          },
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
                        horizontal: 8,
                        vertical: 4,
                      ),
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

                // Hexagram content (parsed from JSON)
                if (gua.content != null) ...[
                  if (gua.content!.guaSymbol.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        gua.content!.guaSymbol,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (gua.content!.guaCi.isNotEmpty)
                    Text(
                      gua.content!.guaCi,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (gua.content!.symbolicMeaning.summary.isNotEmpty)
                    Text(
                      gua.content!.symbolicMeaning.summary,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single hexagram line: solid (━━━) or broken (━ ━).
class _HexagramLine extends StatelessWidget {
  final bool isSolid;
  final Color color;

  const _HexagramLine({required this.isSolid, required this.color});

  @override
  Widget build(BuildContext context) {
    if (isSolid) {
      return Container(
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    // Broken line: two shorter segments with a gap in the middle.
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hexagram line pattern mapping
// ---------------------------------------------------------------------------

/// Returns the 6-line pattern for a hexagram by parsing the trigram info
/// from the hexagram's JSON content (卦象, e.g. "䷭（下巽上坤）").
///
/// Each element is `true` for a solid (yang) line or `false` for a broken
/// (yin) line. Index 0 = bottom line (line 1), index 5 = top line (line 6).
List<bool> _hexagramLines(Gua gua) {
  final symbol = gua.content?.guaSymbol ?? '';
  return TrigramHexagramData.linesFromSymbol(symbol);
}
