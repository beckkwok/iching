import 'package:flutter/material.dart';
import '../data/trigram_hexagram_data.dart';
import '../l10n/app_localizations.dart';
import '../models/hexagram_content.dart';
import '../models/language_preference.dart';
import '../models/question_type.dart';
import '../models/yao_line_type.dart';
import '../services/database_service.dart';
import '../services/gua_generator.dart';
import '../services/hexagram_reading.dart';
import '../services/llm_service.dart';
import '../widgets/gradient_button.dart';
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

  /// The selected question category, used to highlight the matching entry in
  /// 生活與占事常見象徵.
  final QuestionType? questionType;

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
    this.questionType,
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

          // 結果 — a quick, non-LLM reading: 象徵意義 + 爻辭 (modern 通解).
          if (content != null) ...[
            _ResultSection(
              content: content,
              questionType: questionType,
              lineTypes: lineTypes,
            ),
            const SizedBox(height: 16),
          ],

          // Get explanation
          if (question != null && question!.isNotEmpty)
            SizedBox(
              height: 48,
              child: GradientButton(
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
                label: l10n.getExplanation,
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

/// The 結果 section: a quick, non-LLM reading of the cast.
///
/// Shows 象徵意義 (with the entry matching the question type highlighted) and
/// 爻辭 — the "modern vernacular / general" interpretation, with the changing
/// (老陰/老陽) lines highlighted.
class _ResultSection extends StatelessWidget {
  final HexagramContent content;
  final QuestionType? questionType;
  final List<YaoLineType> lineTypes;

  const _ResultSection({
    required this.content,
    required this.questionType,
    required this.lineTypes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final modern = HexagramReading.modern(content.interpretations);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.resultSection,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.symbolicMeaning,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _SymbolicMeaningView(
              meaning: content.symbolicMeaning,
              highlightKey: HexagramReading.lifeKeyForQuestionType(questionType),
            ),
            if (modern != null) ...[
              const SizedBox(height: 20),
              Text(
                l10n.lineTexts,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _ModernInterpretationView(
                interpretation: modern,
                highlightPositions: HexagramReading.changingPositions(lineTypes),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders a [SymbolicMeaning], highlighting the [highlightKey] life-symbol.
class _SymbolicMeaningView extends StatelessWidget {
  final SymbolicMeaning meaning;
  final String? highlightKey;

  const _SymbolicMeaningView({required this.meaning, this.highlightKey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final basic = meaning.basicSymbol;
    final hasBasic =
        basic.composition.isNotEmpty ||
        basic.naturalImage.isNotEmpty ||
        basic.explanation.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasBasic) ...[
          if (basic.composition.isNotEmpty)
            Text('${l10n.structure}：${basic.composition}'),
          if (basic.naturalImage.isNotEmpty)
            Text('${l10n.naturalImage}：${basic.naturalImage}'),
          if (basic.explanation.isNotEmpty)
            Text('${l10n.explanationLabel}：${basic.explanation}'),
          const SizedBox(height: 12),
        ],
        if (meaning.mainSymbols.isNotEmpty) ...[
          for (final symbol in meaning.mainSymbols)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ${symbol.title}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (symbol.content.isNotEmpty) Text(symbol.content),
                ],
              ),
            ),
          const SizedBox(height: 4),
        ],
        if (meaning.lifeSymbols.isNotEmpty) ...[
          Text(
            l10n.lifeSymbols,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          for (final entry in meaning.lifeSymbols.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _Highlighted(
                highlighted: highlightKey != null && entry.key == highlightKey,
                child: Text('${entry.key}：${entry.value}'),
              ),
            ),
        ],
        if (meaning.summary.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            meaning.summary,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }
}

/// Renders the "modern vernacular / general" interpretation, highlighting the
/// line interpretations whose 爻位 is in [highlightPositions].
class _ModernInterpretationView extends StatelessWidget {
  final Interpretation interpretation;
  final Set<String> highlightPositions;

  const _ModernInterpretationView({
    required this.interpretation,
    required this.highlightPositions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (interpretation.judgmentInterpretation.isNotEmpty)
          Text(
            '${l10n.judgmentInterpretation}：'
            '${interpretation.judgmentInterpretation}',
          ),
        if (interpretation.lineInterpretations.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final entry in interpretation.lineInterpretations.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _Highlighted(
                highlighted: highlightPositions.contains(entry.key),
                child: Text(
                  '${entry.key}：${entry.value}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Wraps [child] in a tinted, bordered highlight when [highlighted].
class _Highlighted extends StatelessWidget {
  final Widget child;
  final bool highlighted;

  const _Highlighted({required this.child, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    if (!highlighted) return child;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
      child: child,
    );
  }
}

