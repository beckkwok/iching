import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../services/llm_service.dart';
import '../widgets/gradient_button.dart';

/// Allows the user to view and edit the LLM system prompt.
///
/// Loads the current prompt (custom if saved, else the default), lets the
/// user modify it, and persists it to the settings table and the
/// [LlmService.systemPrompt] field.
class PromptEditorScreen extends StatefulWidget {
  final LlmService? llmService;
  final DatabaseService? databaseService;

  const PromptEditorScreen({
    super.key,
    this.llmService,
    required this.databaseService,
  });

  @override
  State<PromptEditorScreen> createState() => _PromptEditorScreenState();
}

class _PromptEditorScreenState extends State<PromptEditorScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    String prompt = '';
    final db = widget.databaseService;
    if (db != null) {
      final saved = await db.getSetting(LlmService.systemPromptSettingsKey);
      if (saved != null && saved.isNotEmpty) {
        prompt = saved;
      }
    }
    if (prompt.isEmpty) {
      prompt = widget.llmService?.systemPrompt ?? '';
    }
    if (mounted) {
      _controller.text = prompt;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    setState(() => _saving = true);
    try {
      // Apply to the live LLM service and persist for future launches.
      widget.llmService?.systemPrompt = text;
      final db = widget.databaseService;
      if (db != null) {
        await db.setSetting(LlmService.systemPromptSettingsKey, text);
      }
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.promptSaved)));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).failedToSavePrompt('$e')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reset() async {
    _controller.text = widget.llmService?.systemPrompt ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.systemPrompt),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.editInstruction,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText: l10n.promptHint,
                              border: const OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _reset,
                          icon: const Icon(Icons.restart_alt),
                          label: Text(l10n.reset),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientButton(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: l10n.save,
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
