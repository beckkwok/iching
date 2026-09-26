import 'package:flutter/material.dart';
import '../data/trigram_hexagram_data.dart';
import '../l10n/app_localizations.dart';
import '../models/gua.dart';
import '../models/hexagram_content.dart';
import '../widgets/hexagram_view.dart';

/// Full-screen detail view of a single hexagram, rendered as a collapsible tree.
///
/// Sections and their default expansion:
/// - 卦象 (expanded)
/// - 象徵意義 (expanded)
/// - 解釋 (expanded)
///   - 現代白話／通解 (expanded)
///   - 其他的解釋 (collapsed, one tile per commentator)
/// - 原文 (collapsed): 卦辭, 彖傳, 大象傳, 爻辭
/// - 備註 (collapsed)
class HexagramDetailScreen extends StatelessWidget {
  final Gua gua;

  const HexagramDetailScreen({super.key, required this.gua});

  @override
  Widget build(BuildContext context) {
    final content = gua.content;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(gua.guaName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: content == null
          ? _buildUnparseable(context)
          : ListView(
              padding: const EdgeInsets.all(12),
              children: _buildTree(context, content),
            ),
    );
  }

  List<Widget> _buildTree(BuildContext context, HexagramContent content) {
    final l10n = AppLocalizations.of(context);
    final modern = content.interpretations
        .where(_isModern)
        .toList(growable: false);
    final others = content.interpretations
        .where((i) => !_isModern(i))
        .toList(growable: false);

    return [
      // 卦象
      _TreeTile(
        title: l10n.hexagramSymbolSection,
        initiallyExpanded: true,
        top: true,
        child: _HexagramContent(gua: gua),
      ),
      // 象徵意義
      _TreeTile(
        title: l10n.symbolicMeaning,
        initiallyExpanded: true,
        top: true,
        child: _SymbolicMeaningContent(meaning: content.symbolicMeaning),
      ),
      // 解釋
      _TreeTile(
        title: l10n.interpretations,
        initiallyExpanded: true,
        top: true,
        children: [
          if (modern.isNotEmpty)
            _TreeTile(
              title: l10n.modernInterpretation,
              initiallyExpanded: true,
              children: [
                for (final interpretation in modern)
                  _InterpretationContent(interpretation: interpretation),
              ],
            ),
          if (others.isNotEmpty)
            _TreeTile(
              title: l10n.otherInterpretations,
              initiallyExpanded: false,
              children: [
                for (final interpretation in others)
                  _TreeTile(
                    title: interpretation.commentator,
                    initiallyExpanded: false,
                    child: _InterpretationContent(
                      interpretation: interpretation,
                    ),
                  ),
              ],
            ),
        ],
      ),
      // 原文
      _TreeTile(
        title: l10n.originalText,
        initiallyExpanded: false,
        top: true,
        children: [
          if (content.guaCi.isNotEmpty)
            _TreeTile(
              title: l10n.judgment,
              initiallyExpanded: false,
              child: Text(content.guaCi),
            ),
          if (content.tuanZhuan.isNotEmpty)
            _TreeTile(
              title: l10n.tuanCommentary,
              initiallyExpanded: false,
              child: Text(content.tuanZhuan),
            ),
          if (content.daXiangZhuan.isNotEmpty)
            _TreeTile(
              title: l10n.greatImage,
              initiallyExpanded: false,
              child: Text(content.daXiangZhuan),
            ),
          if (content.lines.isNotEmpty)
            _TreeTile(
              title: l10n.lineTexts,
              initiallyExpanded: false,
              child: _LinesContent(lines: content.lines),
            ),
        ],
      ),
      // 備註
      if (content.remarks.isNotEmpty)
        _TreeTile(
          title: l10n.remarks,
          initiallyExpanded: false,
          top: true,
          child: Text(content.remarks),
        ),
    ];
  }

  /// The "modern vernacular / general" interpretation (e.g. 現代白話／通解).
  static bool _isModern(Interpretation interpretation) =>
      interpretation.commentator.contains('白話') ||
      interpretation.commentator.contains('通解');

  Widget _buildUnparseable(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          AppLocalizations.of(context).unableToRead(gua.guaName),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// A collapsible node in the detail tree.
///
/// Top-level nodes ([top]) are card-styled; nested nodes are plain,
/// indented expansion tiles.
class _TreeTile extends StatelessWidget {
  final String title;
  final bool initiallyExpanded;
  final Widget? child;
  final List<Widget> children;
  final bool top;

  const _TreeTile({
    required this.title,
    required this.initiallyExpanded,
    this.child,
    this.children = const [],
    this.top = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = ExpansionTile(
      title: Text(
        title,
        style: top
            ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            : theme.textTheme.titleSmall,
      ),
      initiallyExpanded: initiallyExpanded,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (child != null) child!,
        ...children,
      ],
    );

    if (!top) return tile;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceContainerHighest,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: tile,
    );
  }
}

/// The 卦象 section: number badge, name, 6-line pattern, and symbol.
class _HexagramContent extends StatelessWidget {
  final Gua gua;

  const _HexagramContent({required this.gua});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final content = gua.content!;
    final lines = content.guaSymbol.isNotEmpty
        ? TrigramHexagramData.linesFromSymbol(content.guaSymbol)
        : [false, false, false, false, false, false];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.hexagramNumber(gua.guaCode),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                content.guaName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 6-line pattern (drawn bottom-to-top), taller than it is wide.
        Center(child: HexagramView(lines: lines)),
        if (content.guaSymbol.isNotEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              content.guaSymbol,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ],
    );
  }
}

/// The 象徵意義 section content.
class _SymbolicMeaningContent extends StatelessWidget {
  final SymbolicMeaning meaning;

  const _SymbolicMeaningContent({required this.meaning});

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
          Text(
            l10n.basicSymbol,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          if (basic.composition.isNotEmpty)
            Text('${l10n.structure}：${basic.composition}'),
          if (basic.naturalImage.isNotEmpty)
            Text('${l10n.naturalImage}：${basic.naturalImage}'),
          if (basic.explanation.isNotEmpty)
            Text('${l10n.explanationLabel}：${basic.explanation}'),
          const SizedBox(height: 12),
        ],
        if (meaning.mainSymbols.isNotEmpty) ...[
          Text(
            l10n.mainSymbols,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
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
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          for (final entry in meaning.lifeSymbols.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${entry.key}：${entry.value}'),
            ),
          const SizedBox(height: 8),
        ],
        if (meaning.summary.isNotEmpty) ...[
          Text(
            l10n.summary,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meaning.summary,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }
}

/// The body of a single commentator's interpretation (without the heading,
/// which is the tree tile's title).
class _InterpretationContent extends StatelessWidget {
  final Interpretation interpretation;

  const _InterpretationContent({required this.interpretation});

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
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${entry.key}：${entry.value}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// The 爻辭 section content: the six lines with position, text and 小象傳.
class _LinesContent extends StatelessWidget {
  final List<HexagramLine> lines;

  const _LinesContent({required this.lines});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display bottom-to-top (line 1 first).
        for (final line in lines) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  line.position,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(line.text, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
          if (line.xiaoXiangZhuan.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text(
                '${l10n.smallImage}：${line.xiaoXiangZhuan}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const Divider(height: 16),
        ],
      ],
    );
  }
}
