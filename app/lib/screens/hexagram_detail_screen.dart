import 'package:flutter/material.dart';
import '../data/trigram_hexagram_data.dart';
import '../models/gua.dart';
import '../models/hexagram_content.dart';

/// Full-screen detail view of a single hexagram, rendered as a series of
/// cards. Displays every field of the hexagram's JSON content: 卦象, 卦辭,
/// 彖傳, 大象傳, the six lines (爻辭), 象徵意義, 不同人解讀, and 備註.
class HexagramDetailScreen extends StatelessWidget {
  final Gua gua;

  const HexagramDetailScreen({super.key, required this.gua});

  @override
  Widget build(BuildContext context) {
    final content = gua.content;
    return Scaffold(
      appBar: AppBar(
        title: Text(gua.guaName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: content == null
          ? _buildUnparseable(context)
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _HeaderCard(gua: gua),
                if (content.guaCi.isNotEmpty)
                  _SectionCard(title: '卦辭', child: Text(content.guaCi)),
                if (content.tuanZhuan.isNotEmpty)
                  _SectionCard(title: '彖傳', child: Text(content.tuanZhuan)),
                if (content.daXiangZhuan.isNotEmpty)
                  _SectionCard(title: '大象傳', child: Text(content.daXiangZhuan)),
                if (content.lines.isNotEmpty) _LinesCard(lines: content.lines),
                _SymbolicMeaningCard(meaning: content.symbolicMeaning),
                if (content.interpretations.isNotEmpty)
                  _InterpretationsCard(
                    interpretations: content.interpretations,
                  ),
                if (content.remarks.isNotEmpty)
                  _SectionCard(title: '備註', child: Text(content.remarks)),
              ],
            ),
    );
  }

  Widget _buildUnparseable(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Unable to read the hexagram content for ${gua.guaName}.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Header card: name, sequence number, symbol, and the 6-line pattern.
class _HeaderCard extends StatelessWidget {
  final Gua gua;

  const _HeaderCard({required this.gua});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = gua.content!;
    final lines = content.guaSymbol.isNotEmpty
        ? TrigramHexagramData.linesFromSymbol(content.guaSymbol)
        : [false, false, false, false, false, false];

    return _Card(
      child: Column(
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
                  '第${gua.guaCode}卦',
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
          // 6-line pattern (drawn bottom-to-top)
          Center(
            child: SizedBox(
              width: 160,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 5; i >= 0; i--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _Line(isSolid: lines[i]),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (content.guaSymbol.isNotEmpty)
            Center(
              child: Text(
                content.guaSymbol,
                style: theme.textTheme.titleMedium,
              ),
            ),
        ],
      ),
    );
  }
}

/// A single yao line bar: solid (━━━) or broken (━ ━).
class _Line extends StatelessWidget {
  final bool isSolid;

  const _Line({required this.isSolid});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    if (isSolid) {
      return Container(
        height: 5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            height: 5,
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

/// Card listing the six lines (爻辭) with position + text + 小象傳.
class _LinesCard extends StatelessWidget {
  final List<HexagramLine> lines;

  const _LinesCard({required this.lines});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      title: '爻辭',
      child: Column(
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
                padding: const EdgeInsets.only(left: 0, top: 2, bottom: 8),
                child: Text(
                  '小象傳：${line.xiaoXiangZhuan}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const Divider(height: 16),
          ],
        ],
      ),
    );
  }
}

/// Card for the 象徵意義 section.
class _SymbolicMeaningCard extends StatelessWidget {
  final SymbolicMeaning meaning;

  const _SymbolicMeaningCard({required this.meaning});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final basic = meaning.basicSymbol;
    final hasBasic =
        basic.composition.isNotEmpty ||
        basic.naturalImage.isNotEmpty ||
        basic.explanation.isNotEmpty;

    return _SectionCard(
      title: '象徵意義',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBasic) ...[
            Text(
              '基本卦象',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            if (basic.composition.isNotEmpty) Text('卦體：${basic.composition}'),
            if (basic.naturalImage.isNotEmpty)
              Text('自然取象：${basic.naturalImage}'),
            if (basic.explanation.isNotEmpty) Text('說明：${basic.explanation}'),
            const SizedBox(height: 12),
          ],
          if (meaning.mainSymbols.isNotEmpty) ...[
            Text(
              '主要象徵',
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
              '生活與占事常見象徵',
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
              '總結',
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
      ),
    );
  }
}

/// Card listing the different commentators' interpretations.
class _InterpretationsCard extends StatelessWidget {
  final List<Interpretation> interpretations;

  const _InterpretationsCard({required this.interpretations});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      title: '不同人解讀',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final interpretation in interpretations) ...[
            Text(
              interpretation.commentator,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (interpretation.judgmentInterpretation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('卦辭解讀：${interpretation.judgmentInterpretation}'),
              ),
            if (interpretation.lineInterpretations.isNotEmpty) ...[
              const SizedBox(height: 4),
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
            const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

/// A titled card container.
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Base card container with consistent styling.
class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceContainerHighest,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
