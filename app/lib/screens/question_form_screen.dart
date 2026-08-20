import 'package:flutter/material.dart';
import '../models/language_preference.dart';
import '../services/database_service.dart';
import '../services/gua_generator.dart';
import '../services/llm_service.dart';
import 'cast_result_screen.dart';
import 'hexagram_browser_screen.dart';

/// Question categories the user can choose from when starting a consultation.
enum QuestionType {
  careerAchievement('Career Achievement', Icons.work_outline),
  intellectualMoralCultivation(
    'Intellectual and moral cultivation',
    Icons.school_outlined,
  ),
  timing('Timing', Icons.schedule_outlined),
  attitude('Attitude', Icons.self_improvement_outlined);

  final String label;
  final IconData icon;

  const QuestionType(this.label, this.icon);
}

/// First screen of the consultation flow: asks the user what kind of question
/// they want to ask, captures the exact question text, and submits it.
///
/// On submit with hexagram generation enabled, casts a hexagram via
/// [GuaGenerator] and shows it in [CastResultScreen].
class QuestionFormScreen extends StatefulWidget {
  final DatabaseService? databaseService;
  final LlmService? llmService;

  const QuestionFormScreen({
    super.key,
    required this.databaseService,
    this.llmService,
  });

  @override
  State<QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends State<QuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  QuestionType? _selectedType;
  bool _generateHexagram = true;
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

    setState(() => _isSubmitting = true);
    try {
      if (_generateHexagram) {
        // Cast a hexagram and show the result with its yao line types.
        final db = widget.databaseService;
        if (db != null) {
          // Load the user's language preference for the explanation prompt.
          final langCode = await db.getSetting(LanguagePreference.settingsKey);
          final language = LanguagePreference.fromCode(langCode);

          final generator = GuaGenerator(db);
          final result = await generator.generateRandom();
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CastResultScreen(
                result: result,
                question: question,
                questionTypeLabel: type.label,
                llmService: widget.llmService,
                language: language,
              ),
            ),
          );
          return;
        }
      }

      // No DB or generation disabled — nothing to show yet.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable hexagram generation to begin your reading.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('I-Ching Consultation'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
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
                    'What would you like to ask the I-Ching?',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),

                  // Question type selector
                  Text('Question type', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<QuestionType>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Select a category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final type in QuestionType.values)
                        DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(type.icon, size: 18),
                              const SizedBox(width: 8),
                              Text(type.label),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _selectedType = value),
                    validator: (value) =>
                        value == null ? 'Please select a question type' : null,
                  ),
                  const SizedBox(height: 16),

                  // Exact question
                  Text('Your question', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _questionController,
                    maxLines: 4,
                    minLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Type your question here...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Please enter your question'
                        : null,
                    textInputAction: TextInputAction.newline,
                  ),
                  const SizedBox(height: 8),

                  // Generate hexagram toggle
                  CheckboxListTile(
                    value: _generateHexagram,
                    onChanged: (value) =>
                        setState(() => _generateHexagram = value ?? true),
                    title: const Text('Help me to generate hexagram'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.question_answer),
                      label: Text(
                        _isSubmitting ? 'Casting...' : 'Submit Question',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Browse hexagrams
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HexagramBrowserScreen(
                              databaseService: widget.databaseService,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.grid_view),
                      label: const Text('Browse Hexagrams'),
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
