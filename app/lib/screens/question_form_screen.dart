import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/language_preference.dart';
import '../models/question_type.dart';
import '../services/database_service.dart';
import '../services/gua_generator.dart';
import '../services/llm_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
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

  /// Champagne field border shared by the dropdown and question inputs.
  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enableGenerationHint)));
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
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: champagneGold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: champagneGold.withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
                          BoxShadow(
                            color: champagneGold.withValues(alpha: 0.15),
                            blurRadius: 28,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                          child: ClipOval(
                            // The artwork has white margins around the coin:
                            // zoom slightly so the coin edge bleeds past the
                            // circular clip and no white ring shows.
                            child: Transform.scale(
                              scale: 1.06,
                              child: Image.asset(
                                'assets/images/medallion.png',
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.askPrompt,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),

                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Question type selector
                        Text(
                          l10n.questionType,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<QuestionType>(
                          initialValue: _selectedType,
                          iconEnabledColor: isDark
                              ? const Color(0xFFE6D5B8)
                              : const Color(0xFFC5B358),
                          decoration: InputDecoration(
                            labelText: l10n.selectCategory,
                            filled: true,
                            fillColor: isDark
                                ? theme.colorScheme.surface.withValues(
                                    alpha: 0.25,
                                  )
                                : Colors.white,
                            enabledBorder: _fieldBorder(
                              isDark
                                  ? champagneGold.withValues(alpha: 0.6)
                                  : bronzeGold,
                            ),
                            focusedBorder: _fieldBorder(
                              isDark ? champagneGold : bronzeGold,
                              width: 2,
                            ),
                            border: _fieldBorder(
                              isDark
                                  ? champagneGold.withValues(alpha: 0.6)
                                  : bronzeGold,
                            ),
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
                        const SizedBox(height: 20),

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
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? theme.colorScheme.surface.withValues(
                                    alpha: 0.25,
                                  )
                                : Colors.white,
                            enabledBorder: _fieldBorder(
                              isDark
                                  ? champagneGold.withValues(alpha: 0.6)
                                  : bronzeGold,
                            ),
                            focusedBorder: _fieldBorder(
                              isDark ? champagneGold : bronzeGold,
                              width: 2,
                            ),
                            border: _fieldBorder(
                              isDark
                                  ? champagneGold.withValues(alpha: 0.6)
                                  : bronzeGold,
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? l10n.enterQuestionError
                              : null,
                          textInputAction: TextInputAction.newline,
                        ),
                        const SizedBox(height: 20),

                        // Casting method — two separated pills, each fully
                        // oval on both sides.
                        Text(
                          l10n.castingMethod,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final method in CastMethod.values) ...[
                              if (method != CastMethod.values.first)
                                const SizedBox(width: 8),
                              Expanded(
                                child: _MethodPill(
                                  key: ValueKey('method-${method.name}'),
                                  selected: _method == method,
                                  icon: method == CastMethod.quick
                                      ? Icons.casino_outlined
                                      : Icons.tune,
                                  label: method == CastMethod.quick
                                      ? l10n.quickGenerate
                                      : l10n.manualGenerate,
                                  onTap: () =>
                                      setState(() => _method = method),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Submit button — same gold gradient + dark text as
                        // the selected casting pill.
                        SizedBox(
                          height: 48,
                          child: GradientButton(
                            onPressed: _isSubmitting ? null : _submit,
                            gradientColors: const [
                              champagneGold,
                              bronzeGold,
                            ],
                            foregroundColor: Colors.black,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One half of the casting-method toggle: a full pill, gold gradient + dark
/// text when selected, transparent + gold outline/text otherwise.
class _MethodPill extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MethodPill({
    super.key,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.black : champagneGold;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: selected
              ? const LinearGradient(
                  colors: [champagneGold, bronzeGold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.transparent,
          border: Border.all(
            color: selected
                ? champagneGold
                : champagneGold.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.check : icon,
              color: foreground,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
