import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/language_preference.dart';
import '../models/question_type.dart';
import '../models/yao_line_type.dart';
import '../services/database_service.dart';
import '../services/gua_generator.dart';
import '../services/llm_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/hexagram_view.dart';
import '../widgets/twinkling_stars.dart';
import 'cast_result_screen.dart';

/// Lets the user build a hexagram line by line (issue #20).
///
/// Six yao lines are shown; tapping one lets the user pick
/// 少陰/少陽/老陰/老陽. The resulting hexagram is resolved live, and the user
/// proceeds to [CastResultScreen] with their manual cast.
class ManualCastScreen extends StatefulWidget {
  final String question;
  final String? questionTypeLabel;
  final QuestionType? questionType;
  final GuaGenerator generator;
  final LlmService? llmService;
  final DatabaseService? databaseService;
  final LanguagePreference language;

  const ManualCastScreen({
    super.key,
    required this.question,
    required this.generator,
    this.questionTypeLabel,
    this.questionType,
    this.llmService,
    this.databaseService,
    this.language = LanguagePreference.english,
  });

  @override
  State<ManualCastScreen> createState() => _ManualCastScreenState();
}

class _ManualCastScreenState extends State<ManualCastScreen> {
  /// The six lines, bottom (index 0) to top (index 5). Defaults to 少陽 so a
  /// valid hexagram always resolves.
  final List<YaoLineType> _lineTypes =
      List<YaoLineType>.filled(6, YaoLineType.youngYang);

  GenerationResult? _result;
  bool _resolving = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  List<bool> get _lines => _lineTypes.map((t) => t.isYang).toList();

  Future<void> _resolve() async {
    setState(() => _resolving = true);
    final result = await widget.generator.resolveCast(
      _lines,
      lineTypes: List.of(_lineTypes),
      method: GeneratorMethod.manual,
    );
    if (mounted) {
      setState(() {
        _result = result;
        _resolving = false;
      });
    }
  }

  Future<void> _pickLine(int index) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<YaoLineType>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.manualCastLine(index + 1),
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            for (final type in YaoLineType.values)
              ListTile(
                leading: Icon(
                  type.isYang ? Icons.horizontal_rule : Icons.drag_handle,
                ),
                title: Text(type.label),
                trailing: _lineTypes[index] == type
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(ctx).pop(type),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _lineTypes[index] = selected);
    await _resolve();
  }

  void _proceed() {
    final result = _result;
    if (result == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CastResultScreen(
          result: result,
          question: widget.question,
          questionTypeLabel: widget.questionTypeLabel,
          questionType: widget.questionType,
          llmService: widget.llmService,
          databaseService: widget.databaseService,
          language: widget.language,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.manualCastTitle),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isDark) const TwinklingStars(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.manualCastHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                HexagramView(lines: _lines),
                const SizedBox(height: 8),
                Text(
                  _resolving
                      ? l10n.loading
                      : (_result?.gua.guaName ?? ''),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Top line first, matching how a hexagram is drawn.
                        for (var i = 5; i >= 0; i--)
                          _LineTile(
                            type: _lineTypes[i],
                            onTap: () => _pickLine(i),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 48,
                    child: GradientButton(
                      onPressed: _resolving ? null : _proceed,
                      icon: const Icon(Icons.auto_awesome),
                      label: l10n.manualCastProceed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable row for one yao line.
class _LineTile extends StatelessWidget {
  final YaoLineType type;
  final VoidCallback onTap;

  const _LineTile({
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = type.isChanging
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        title: _bar(color),
        trailing: Text(
          type.label,
          style: theme.textTheme.labelMedium?.copyWith(color: color),
        ),
      ),
    );
  }

  Widget _bar(Color color) {
    Widget segment() => Container(
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
    if (type.isYang) return segment();
    return Row(
      children: [
        Expanded(child: segment()),
        const SizedBox(width: 12),
        Expanded(child: segment()),
      ],
    );
  }
}
