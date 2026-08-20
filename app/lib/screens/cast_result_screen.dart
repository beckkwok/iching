import 'package:flutter/material.dart';
import '../models/language_preference.dart';
import '../models/yao_line_type.dart';
import '../services/gua_generator.dart';
import '../services/llm_service.dart';
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

  /// Language preference for the explanation response.
  final LanguagePreference language;

  const CastResultScreen({
    super.key,
    required this.result,
    this.question,
    this.questionTypeLabel,
    this.llmService,
    this.language = LanguagePreference.english,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gua = result.gua;
    final content = gua.content;
    final symbol = content?.guaSymbol ?? '';
    final lineTypes = result.lineTypes;

    return Scaffold(
      appBar: AppBar(
        title: Text(gua.guaName),
        backgroundColor: theme.colorScheme.inversePrimary,
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
                      '第${gua.guaCode}卦',
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
                    if (symbol.isNotEmpty)
                      Text(
                        symbol,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium,
                      )
                    else
                      Icon(
                        Icons.auto_awesome,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap for details',
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
              '爻象',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Display bottom → top: line 1 (index 0) at the bottom.
            for (int i = lineTypes.length - 1; i >= 0; i--)
              _YaoLineRow(lineType: lineTypes[i], lineIndex: i),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No cast details available.'),
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
                        language: language,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Get Explanation'),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 爻位
          SizedBox(
            width: 40,
            child: Text(
              _positionLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Line pattern (solid or broken)
          Expanded(
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
                      const SizedBox(width: 20),
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
          Container(
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
        ],
      ),
    );
  }
}
