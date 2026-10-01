import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/language_preference.dart';
import '../models/question_type.dart';
import '../services/database_service.dart';
import '../services/gua_generator.dart';
import '../services/llm_service.dart';
import '../widgets/gradient_button.dart';
import 'cast_result_screen.dart';
import 'manual_cast_screen.dart';

/// How the hexagram is produced (issue #20). "Full Generate" is tracked
/// separately in issue #51.
enum CastMethod { quick, manual }

/// First screen of the consultation flow: asks the user what kind of question
/// they want to ask, captures the exact question text, and submits it.
///
/// On submit with hexagram generation enabled, casts a hexagram via
/// [GuaGenerator] and shows it in [CastResultScreen].
class QuestionFormScreen extends StatefulWidget {
  final DatabaseService? databaseService;
  final LlmService? llmService;

  /// Optional generator for tests. When omitted, a [GuaGenerator] backed by
  /// the bundled JSON assets is used.
  final GuaGenerator? guaGenerator;

  const QuestionFormScreen({
    super.key,
    required this.databaseService,
    this.llmService,
    this.guaGenerator,
  });

  @override
  State<QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends State<QuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  QuestionType? _selectedType;
  CastMethod _method = CastMethod.quick;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSubmitting) return;

    final question = _questionController.text.trim();
    final type = _selectedType ?? QuestionType.attitude;
    final l10n = AppLocalizations.of(context);
    // Send the category in the active language (shown on the explanation page).
    final typeLabel = l10n.questionTypeLabel(type);

    final db = widget.databaseService;
    if (db == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enableGenerationHint)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Load the user's language preference for the explanation prompt.
      final langCode = await db.getSetting(LanguagePreference.settingsKey);
      final language = LanguagePreference.fromCode(langCode);
      final generator = widget.guaGenerator ?? GuaGenerator();
      if (!mounted) return;

      if (_method == CastMethod.manual) {
        // Build the hexagram line by line (issue #20).
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ManualCastScreen(
              question: question,
              questionTypeLabel: typeLabel,
              questionType: type,
              generator: generator,
              llmService: widget.llmService,
              databaseService: widget.databaseService,
              language: language,
            ),
          ),
        );
        return;
      }

      // Quick generate: cast a random hexagram and show the result.
      final result = await generator.generateRandom();
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CastResultScreen(
            result: result,
            question: question,
            questionTypeLabel: typeLabel,
            questionType: type,
            llmService: widget.llmService,
            databaseService: widget.databaseService,
            language: language,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.askPrompt,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),

                      // Question type selector
                      Text(
                        l10n.questionType,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<QuestionType>(
                        initialValue: _selectedType,
                        decoration: InputDecoration(
                          labelText: l10n.selectCategory,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (final type in QuestionType.values)
                            DropdownMenuItem(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(type.icon, size: 18),
                                  const SizedBox(width: 8),
                                  Text(l10n.questionTypeLabel(type)),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedType = value),
                        validator: (value) =>
                            value == null ? l10n.selectTypeError : null,
                      ),
                      const SizedBox(height: 16),

                      // Exact question
                      Text(
                        l10n.yourQuestion,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _questionController,
                        maxLines: 4,
                        minLines: 3,
                        decoration: InputDecoration(
                          hintText: l10n.questionHint,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? l10n.enterQuestionError
                            : null,
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: 8),

                      // Casting method
                      Text(
                        l10n.castingMethod,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<CastMethod>(
                        segments: [
                          ButtonSegment(
                            value: CastMethod.quick,
                            icon: const Icon(Icons.casino_outlined),
                            label: Text(l10n.quickGenerate),
                          ),
                          ButtonSegment(
                            value: CastMethod.manual,
                            icon: const Icon(Icons.tune),
                            label: Text(l10n.manualGenerate),
                          ),
                        ],
                        selected: {_method},
                        onSelectionChanged: (selection) =>
                            setState(() => _method = selection.first),
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        height: 48,
                        child: GradientButton(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.question_answer),
                          label: _isSubmitting
                              ? l10n.casting
                              : l10n.submitQuestion,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
