import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/consultation.dart';
import '../models/gua.dart';
import '../models/reaction.dart';
import '../widgets/hexagram_view.dart';
import 'hexagram_detail_screen.dart';

/// Shows the complete saved record for a consultation (issue #47):
/// the question, the original hexagram, the changed hexagram, the LLM
/// explanation and the user's feedback.
class ConsultationDetailScreen extends StatelessWidget {
  final Consultation consultation;

  const ConsultationDetailScreen({super.key, required this.consultation});

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  /// Open the full hexagram explanation (卦辭/彖傳/爻辭/...) for [gua].
  void _openGua(
    BuildContext context, {
    required int guaCode,
    required String guaName,
    required String guaContent,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HexagramDetailScreen(
          gua: Gua(guaCode: guaCode, guaName: guaName, guaContent: guaContent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final reaction = Reaction.fromKey(consultation.reaction);
    final comment = consultation.comment;
    final typeLabel = consultation.questionTypeLabel;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.consultationDetail)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              consultation.question,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (typeLabel != null && typeLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                typeLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDate(consultation.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 32),

            // 1-3. Original hexagram | changed lines | changed hexagram, side
            // by side so the change is visible at a glance (issue #47).
            // Tapping either figure opens its full explanation.
            _Section(
              title: l10n.hexagramSymbolSection,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _HexagramColumn(
                      label: l10n.original,
                      name: consultation.hexagramName,
                      number: l10n.hexagramNumber(consultation.hexagramCode),
                      view: consultation.lineTypes.isNotEmpty
                          ? HexagramView(
                              lines: consultation.castLines,
                              lineHeight: 14,
                              gap: 10,
                              labels: [
                                for (final t in consultation.lineTypes) t.label,
                              ],
                              labelColors: [
                                for (final t in consultation.lineTypes)
                                  t.isChanging
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                              ],
                            )
                          : const SizedBox.shrink(),
                      onTap: () => _openGua(
                        context,
                        guaCode: consultation.hexagramCode,
                        guaName: consultation.hexagramName,
                        guaContent: consultation.hexagramContent,
                      ),
                    ),
                  ),
                  if (consultation.hasChangedHexagram) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _HexagramColumn(
                        label: l10n.changed,
                        name: consultation.changedHexagramName ?? '',
                        number: consultation.changedHexagramCode != null
                            ? l10n.hexagramNumber(
                                consultation.changedHexagramCode!,
                              )
                            : '',
                        highlight: true,
                        view: consultation.changedLines.length == 6
                            ? HexagramView(
                                lines: consultation.changedLines,
                                lineHeight: 14,
                                gap: 10,
                              )
                            : const SizedBox.shrink(),
                        onTap: consultation.changedHexagramContent != null
                            ? () => _openGua(
                                context,
                                guaCode: consultation.changedHexagramCode ?? 0,
                                guaName: consultation.changedHexagramName ?? '',
                                guaContent:
                                    consultation.changedHexagramContent!,
                              )
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 4. LLM interpretation.
            _Section(
              title: l10n.explanation,
              child: Text(
                consultation.explanation,
                style: theme.textTheme.bodyMedium,
              ),
            ),

            // 5. User feedback.
            if (reaction != null || (comment != null && comment.isNotEmpty))
              _Section(
                title: l10n.feedbackTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reaction != null)
                      Text(
                        reaction.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    if (comment != null && comment.isNotEmpty) ...[
                      if (reaction != null) const SizedBox(height: 8),
                      Text(
                        comment,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One side of the original → changed comparison: a header (label, name,
/// number), the hexagram figure, and a tap hint when it opens the full
/// explanation.
class _HexagramColumn extends StatelessWidget {
  final String label;
  final String name;
  final String number;
  final Widget view;
  final bool highlight;
  final VoidCallback? onTap;

  const _HexagramColumn({
    required this.label,
    required this.name,
    required this.number,
    required this.view,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: highlight ? theme.colorScheme.primary : null,
              ),
            ),
            if (number.isNotEmpty)
              Text(
                number,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 12),
            Center(child: view),
            if (onTap != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.tapForDetails,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A labelled block in the consultation record.
class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
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
