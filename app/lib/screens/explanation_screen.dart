import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/consultation.dart';
import '../models/language_preference.dart';
import '../services/database_service.dart';
import '../services/gua_generator.dart';
import '../services/llm_service.dart';
import 'hexagram_detail_screen.dart';

/// Shows the one-shot I-Ching explanation for a cast hexagram in relation to
/// the user's question.
///
/// Calls [LlmService.generateExplanation] once (single-shot, no multi-turn
/// history) and displays the result. Falls back to a placeholder message when
/// no LLM is available.
class ExplanationScreen extends StatefulWidget {
  final String question;
  final String? questionTypeLabel;
  final GenerationResult result;
  final LlmService? llmService;

  /// Used to persist the consultation once the explanation is generated.
  final DatabaseService? databaseService;

  /// Language preference for the explanation response.
  final LanguagePreference language;

  const ExplanationScreen({
    super.key,
    required this.question,
    required this.result,
    this.questionTypeLabel,
    this.llmService,
    this.databaseService,
    this.language = LanguagePreference.english,
  });

  @override
  State<ExplanationScreen> createState() => _ExplanationScreenState();
}

class _ExplanationScreenState extends State<ExplanationScreen> {
  String? _explanation;
  bool _loading = true;
  String? _error;

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Run once, after the first build context (and localizations) exist.
    if (_started) return;
    _started = true;
    _generate();
  }

  Future<void> _generate() async {
    final llm = widget.llmService;
    if (llm == null || !llm.isReady) {
      setState(() {
        _loading = false;
        _explanation = AppLocalizations.of(context).noModelExplanation;
      });
      return;
    }
    try {
      final text = await llm.generateExplanation(
        question: widget.question,
        questionTypeLabel: widget.questionTypeLabel,
        result: widget.result,
        language: widget.language,
      );
      // Persist the consultation (issue #8).
      final db = widget.databaseService;
      if (db != null) {
        final gua = widget.result.gua;
        await db.createConsultation(Consultation(
          question: widget.question,
          questionTypeLabel: widget.questionTypeLabel,
          hexagramCode: gua.guaCode,
          hexagramName: gua.guaName,
          explanation: text,
          createdAt: DateTime.now(),
        ));
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _explanation = text;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final gua = widget.result.gua;
    final symbol = gua.content?.guaSymbol ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.explanation),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Question card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.questionTypeLabel != null)
                    Text(
                      widget.questionTypeLabel!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(widget.question, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Hexagram card — tapping opens the full hexagram detail screen.
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
                child: Row(
                  children: [
                    if (symbol.isNotEmpty)
                      Text(symbol, style: theme.textTheme.headlineMedium),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gua.guaName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${l10n.hexagramNumber(gua.guaCode)} · '
                            '${l10n.tapForDetails}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Explanation
          Card(
            elevation: 1,
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
                    l10n.interpretation,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Text(
                      l10n.failedExplanation('$_error'),
                      style: TextStyle(color: theme.colorScheme.error),
                    )
                  else
                    Text(
                      _explanation ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
