import 'package:flutter/material.dart';
import '../data/trigram_hexagram_data.dart';
import '../l10n/app_localizations.dart';
import '../models/language_preference.dart';
import '../models/yao_line_type.dart';
import '../services/database_service.dart';
import '../services/gua_generator.dart';
import '../services/llm_service.dart';
import '../widgets/hexagram_view.dart';
import 'explanation_screen.dart';
import 'hexagram_detail_screen.dart';

/// Shows the result of a hexagram cast: the 卦象 (hexagram symbol) plus each
/// 爻 line with its type (老陰 / 少陽 / 少陰 / 老陽).
///
/// The user's [question] (and optional [questionTypeLabel]) are carried
/// through so a one-shot LLM explanation can be requested.
class CastResultScreen extends StatelessWidget {
  final GenerationResult result;

  /// The user's original question, carried to the explanation screen.
  final String? question;

  /// Human-readable category label (e.g. "Career Achievement").
  final String? questionTypeLabel;

  /// Optional LLM service used to generate the explanation.
  final LlmService? llmService;

  /// Used to persist the consultation when the explanation is generated.
  final DatabaseService? databaseService;

  /// Language preference for the explanation response.
  final LanguagePreference language;

  const CastResultScreen({
    super.key,
    required this.result,
    this.question,
    this.questionTypeLabel,
    this.llmService,
    this.databaseService,
    this.language = LanguagePreference.english,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final gua = result.gua;
    final content = gua.content;
    final symbol = content?.guaSymbol ?? '';
    final lineTypes = result.lineTypes;
    // The six lines to draw: the cast lines when available, else derived from
    // the hexagram symbol.
    final lines = result.hasCast
        ? result.lines
        : TrigramHexagramData.linesFromSymbol(symbol);

    return Scaffold(
      appBar: AppBar(
        title: Text(gua.guaName),
        backgroundColor: theme.colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.backToQuestion,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 卦象 — tapping opens the full hexagram detail screen.
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HexagramDetailScreen(gua: gua),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      l10n.hexagramNumber(gua.guaCode),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gua.guaName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Hexagram figure — taller than it is wide.
                    HexagramView(lines: lines),
                    if (symbol.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        symbol,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      l10n.tapForDetails,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Each yao line with its type
          if (lineTypes.length == 6) ...[
            Text(
              l10n.linePattern,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Display bottom → top: line 1 (index 0) at the bottom.
            for (int i = lineTypes.length - 1; i >= 0; i--)
              _YaoLineRow(lineType: lineTypes[i], lineIndex: i),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noCastDetails),
              ),
            ),
          const SizedBox(height: 16),

          // Get explanation
          if (question != null && question!.isNotEmpty)
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExplanationScreen(
                        question: question!,
                        questionTypeLabel: questionTypeLabel,
                        result: result,
                        llmService: llmService,
                        databaseService: databaseService,
                        language: language,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: Text(l10n.getExplanation),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single yao line row: the line pattern plus its 爻位 and type label.
class _YaoLineRow extends StatelessWidget {
  final YaoLineType lineType;

  /// Index of this line (0 = bottom 初爻, 5 = top 上爻).
  final int lineIndex;

  const _YaoLineRow({required this.lineType, required this.lineIndex});

  String get _positionLabel {
    // 初, 二, 三, 四, 五, 上 (bottom → top).
    const positions = ['初', '二', '三', '四', '五', '上'];
    return positions[lineIndex];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = lineType.isYang
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;

    // The 爻位 and type boxes share a width so the bar sits dead centre.
    const sideWidth = 72.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 爻位
          SizedBox(
            width: sideWidth,
            child: Text(
              _positionLabel,
              textAlign: TextAlign.right,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Line pattern (solid or broken) — narrow so the stacked bars form
          // a tall hexagram figure; a fixed width keeps every bar aligned.
          SizedBox(
            key: ValueKey('yao-bar-$lineIndex'),
            width: 72,
            child: lineType.isYang
                ? Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 12),
          // Type label
          SizedBox(
            width: sideWidth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: lineType.isChanging
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${lineType.label}${lineType.isChanging ? ' 變' : ''}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: lineType.isChanging
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
