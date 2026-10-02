import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/language_preference.dart';
import '../models/question_type.dart';
import '../models/yao_line_type.dart';
import '../services/database_service.dart';
import '../services/gua_generator.dart';
import '../services/hexagram_reading.dart';
import '../services/llm_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/hexagram_view.dart';
import '../widgets/twinkling_stars.dart';
import 'cast_result_screen.dart';

/// Lets the user build a hexagram line by line (issue #20).
///
/// The six lines form a single tall figure like the Quick Generate screen
/// (same bar width/height/gap), but each line is tappable to pick
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
                Text(
                  _resolving ? l10n.loading : (_result?.gua.guaName ?? ''),
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
                        // Tall preview figure, same configuration as Quick
                        // Generate.
                        HexagramView(lines: _lines),
                        const SizedBox(height: 12),
                        // Editable lines, laid out like the Quick Generate
                        // rows: position left, bar center, type right.
                        // Top line first, matching how a hexagram is drawn.
                        for (var i = 5; i >= 0; i--)
                          _EditableYao(
                            key: ValueKey('edit-yao-$i'),
                            type: _lineTypes[i],
                            position: HexagramReading.linePositionLabel(
                              i,
                              _lineTypes[i].isYang,
                            ),
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

/// One tappable yao line, laid out exactly like the Quick Generate rows:
/// position left, narrow bar center, type label right.
class _EditableYao extends StatelessWidget {
  final YaoLineType type;
  final String position;
  final VoidCallback onTap;

  const _EditableYao({
    super.key,
    required this.type,
    required this.position,
    required this.onTap,
  });

  /// Label/pattern column width shared with the Quick Generate rows.
  static const double _sideWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = type.isChanging
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: _sideWidth,
              child: Text(
                position,
                textAlign: TextAlign.right,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 72,
              child: _yaoBar(color),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: _sideWidth,
              child: Text(
                type.label,
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _yaoBar(Color color) {
    Widget segment() => Container(
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        );
    if (type.isYang) return segment();
    return Row(
      children: [
        Expanded(child: segment()),
        const SizedBox(width: 16),
        Expanded(child: segment()),
      ],
    );
  }
}
