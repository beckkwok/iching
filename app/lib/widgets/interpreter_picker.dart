import 'package:flutter/material.dart';

import 'package:app/data/interpreter_catalog.dart';
import 'package:app/l10n/app_localizations.dart';

/// A horizontal set of interpreter choices, each with an avatar + name
/// (issue #22).
class InterpreterPicker extends StatelessWidget {
  final String selectedKey;
  final ValueChanged<String> onSelected;

  const InterpreterPicker({
    super.key,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final interpreter in InterpreterCatalog.all)
          ChoiceChip(
            selected: interpreter.key == selectedKey,
            onSelected: (_) => onSelected(interpreter.key),
            avatar: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.15,
              ),
              child: Icon(
                interpreter.avatar,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            label: Text(interpreter.displayName(l10n.isChinese)),
          ),
      ],
    );
  }
}
