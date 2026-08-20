import 'package:flutter/material.dart';
import '../models/language_preference.dart';
import '../services/gua_generator.dart';
import '../services/llm_service.dart';

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

  /// Language preference for the explanation response.
  final LanguagePreference language;

  const ExplanationScreen({
    super.key,
    required this.question,
    required this.result,
    this.questionTypeLabel,
    this.llmService,
    this.language = LanguagePreference.english,
  });

  @override
  State<ExplanationScreen> createState() => _ExplanationScreenState();
}

class _ExplanationScreenState extends State<ExplanationScreen> {
  String? _explanation;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final llm = widget.llmService;
    if (llm == null || !llm.isReady) {
      setState(() {
        _loading = false;
        _explanation =
            'No model available to provide an explanation. '
            'Here is the hexagram that was cast — reflect on its imagery '
            'in relation to your question.';
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
    final gua = widget.result.gua;
    final symbol = gua.content?.guaSymbol ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explanation'),
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

          // Hexagram card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
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
                          '第${gua.guaCode}卦',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    '解讀',
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
                      'Failed to generate explanation: $_error',
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
