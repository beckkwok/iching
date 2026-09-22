import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../models/language_preference.dart';
import '../services/database_service.dart';
import '../services/llm_service.dart';
import 'model_selection_screen.dart';
import 'prompt_editor_screen.dart';

/// Settings screen accessible from the chat screen's header menu.
class SettingsScreen extends StatefulWidget {
  final LlmService? llmService;
  final DatabaseService? databaseService;

  const SettingsScreen({
    super.key,
    this.llmService,
    required this.databaseService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _modelFilename = '';
  String _modelFullPath = '';
  String _modelDisplayName = '';
  bool _loading = true;
  LanguagePreference _language = LanguagePreference.english;

  bool _modelInfoLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Run once, after the first build context (and localizations) exist.
    if (_modelInfoLoaded) return;
    _modelInfoLoaded = true;
    _loadModelInfo();
  }

  Future<void> _loadLanguage() async {
    final db = widget.databaseService;
    if (db == null) return;
    final code = await db.getSetting(LanguagePreference.settingsKey);
    if (mounted) {
      setState(() => _language = LanguagePreference.fromCode(code));
    }
  }

  Future<void> _setLanguage(LanguagePreference value) async {
    setState(() => _language = value);
    // Update the app-wide locale immediately.
    LocaleScope.maybeOf(context)?.setLanguage(value);
    final db = widget.databaseService;
    if (db != null) {
      await db.setSetting(LanguagePreference.settingsKey, value.code);
    }
  }

  Future<void> _loadModelInfo() async {
    final l10n = AppLocalizations.of(context);
    final svc = widget.llmService;
    if (svc == null) {
      setState(() {
        _modelDisplayName = l10n.noLlmService;
        _modelFilename = l10n.notAvailable;
        _modelFullPath = l10n.notAvailable;
        _loading = false;
      });
      return;
    }
    try {
      final path = await svc.modelFilePath;
      if (mounted) {
        setState(() {
          _modelDisplayName = svc.modelDisplayName;
          _modelFilename = svc.modelFilename;
          _modelFullPath = path;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _modelDisplayName = l10n.error;
          _modelFilename = l10n.error;
          _modelFullPath = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _removeModelFile() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeModelFileTitle),
        content: Text(l10n.removeModelFileBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Delete model file from disk.
      final svc = widget.llmService;
      if (svc != null) {
        await svc.closeChat();
        final path = await svc.modelFilePath;
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Clear the setting.
      final db = widget.databaseService;
      if (db != null) {
        await db.setSetting('selected_model_key', null);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                ModelSelectionScreen(databaseService: widget.databaseService),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.failedToRemoveModel}$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // --- Model ---
                _buildSectionHeader(context, l10n.model),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: Text(l10n.model),
                  subtitle: Text(
                    _modelDisplayName,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(l10n.fileName),
                  subtitle: Text(
                    _modelFilename,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: Text(l10n.fullPath),
                  subtitle: Text(
                    _modelFullPath,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _removeModelFile,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.removeModelFile),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const Divider(),

                // --- Language ---
                _buildSectionHeader(context, l10n.language),
                RadioGroup<LanguagePreference>(
                  groupValue: _language,
                  onChanged: (value) {
                    if (value != null) _setLanguage(value);
                  },
                  child: Column(
                    children: [
                      RadioListTile<LanguagePreference>(
                        value: LanguagePreference.english,
                        title: Text(l10n.english),
                      ),
                      RadioListTile<LanguagePreference>(
                        value: LanguagePreference.chinese,
                        title: Text(l10n.chinese),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // --- Prompts ---
                _buildSectionHeader(context, l10n.prompts),
                ListTile(
                  leading: const Icon(Icons.psychology),
                  title: Text(l10n.systemPrompt),
                  subtitle: Text(l10n.systemPromptSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PromptEditorScreen(
                          llmService: widget.llmService,
                          databaseService: widget.databaseService,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),

                // --- Privacy ---
                _buildSectionHeader(context, l10n.privacy),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.privacyNotice),
                  subtitle: Text(l10n.privacySubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPrivacyNotice(context),
                ),
                const Divider(),

                // --- App Info ---
                _buildSectionHeader(context, l10n.about),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.version),
                  subtitle: const Text('1.0.0'),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showPrivacyNotice(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.privacyNotice),
        content: SingleChildScrollView(child: Text(l10n.privacyNoticeBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}
