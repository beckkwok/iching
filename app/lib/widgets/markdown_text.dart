import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Renders the LLM's Markdown using the app's Material theme.
///
/// [compact] is used inside history cards; [selectable] is enabled on the
/// explanation and consultation-detail screens so the text can be copied.
class MarkdownText extends StatelessWidget {
  final String data;
  final bool selectable;
  final bool compact;

  const MarkdownText(
    this.data, {
    super.key,
    this.selectable = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium ?? const TextStyle();
    final headingColor = theme.colorScheme.primary;
    final style = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: base.copyWith(height: compact ? 1.45 : 1.6),
      h1: theme.textTheme.headlineSmall?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.bold,
      ),
      h2: theme.textTheme.titleLarge?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.bold,
      ),
      h3: theme.textTheme.titleMedium?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.bold,
      ),
      h4: theme.textTheme.titleSmall?.copyWith(
        color: headingColor,
        fontWeight: FontWeight.bold,
      ),
      listBullet: base,
      blockSpacing: compact ? 6 : 10,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
    );

    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: style,
    );
  }
}
