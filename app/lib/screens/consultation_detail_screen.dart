import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/consultation.dart';
import '../models/reaction.dart';
import '../widgets/hexagram_view.dart';

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

            // 1. Hexagram result (plus the cast lines when known).
            _Section(
              title: l10n.hexagramSymbolSection,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          consultation.hexagramName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        l10n.hexagramNumber(consultation.hexagramCode),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (consultation.lineTypes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    HexagramView(
                      lines: consultation.castLines,
                      labels: [
                        for (final t in consultation.lineTypes)
                          '${t.label}${t.isChanging ? ' →' : ''}',
                      ],
                      labelColors: [
                        for (final t in consultation.lineTypes)
                          t.isChanging
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // 2 + 3. Changed lines / changed hexagram.
            if (consultation.hasChangedHexagram)
              _Section(
                title: l10n.changedHexagram,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            consultation.changedHexagramName ?? '',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (consultation.changedHexagramCode != null)
                          Text(
                            l10n.hexagramNumber(
                              consultation.changedHexagramCode!,
                            ),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    if (consultation.changedLines.length == 6) ...[
                      const SizedBox(height: 12),
                      HexagramView(lines: consultation.changedLines),
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
