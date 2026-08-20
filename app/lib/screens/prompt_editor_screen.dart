import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/llm_service.dart';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Prompt saved.')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save prompt: $e')));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Prompt'),
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
                          'Edit the instruction sent to the model before each '
                          'consultation. Keep the JSON response instruction '
                          'intact.',
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
                            decoration: const InputDecoration(
                              hintText: 'Enter your system prompt...',
                              border: OutlineInputBorder(),
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
                          label: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: const Text('Save'),
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
