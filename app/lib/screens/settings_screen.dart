import 'dart:io';
import 'package:flutter/material.dart';
import '../models/language_preference.dart';
import '../services/database_service.dart';
import '../services/llm_service.dart';
import 'model_selection_screen.dart';

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
  String _modelFilename = 'Loading...';
  String _modelFullPath = 'Loading...';
  String _modelDisplayName = 'Loading...';
  bool _loading = true;
  LanguagePreference _language = LanguagePreference.english;

  @override
  void initState() {
    super.initState();
    _loadModelInfo();
    _loadLanguage();
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
    final db = widget.databaseService;
    if (db != null) {
      await db.setSetting(LanguagePreference.settingsKey, value.code);
    }
  }

  Future<void> _loadModelInfo() async {
    final svc = widget.llmService;
    if (svc == null) {
      setState(() {
        _modelDisplayName = 'No LLM service';
        _modelFilename = 'Not available';
        _modelFullPath = 'Not available';
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
          _modelDisplayName = 'Error';
          _modelFilename = 'Error';
          _modelFullPath = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _removeModelFile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Model File?'),
        content: const Text(
          'This will delete the model file and reset your selection. '
          'The app will restart with the model selection screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove model: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // --- Model ---
                _buildSectionHeader(context, 'Model'),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Model'),
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
                  title: const Text('File Name'),
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
                  title: const Text('Full Path'),
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
                    label: const Text('Remove Model File'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const Divider(),

                // --- Language ---
                _buildSectionHeader(context, 'Language'),
                RadioGroup<LanguagePreference>(
                  groupValue: _language,
                  onChanged: (value) {
                    if (value != null) _setLanguage(value);
                  },
                  child: Column(
                    children: [
                      const RadioListTile<LanguagePreference>(
                        value: LanguagePreference.english,
                        title: Text('English'),
                      ),
                      const RadioListTile<LanguagePreference>(
                        value: LanguagePreference.chinese,
                        title: Text('中文 (Chinese)'),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // --- Prompts ---
                _buildSectionHeader(context, 'Prompts'),
                ListTile(
                  leading: const Icon(Icons.psychology),
                  title: const Text('System Prompt'),
                  subtitle: const Text('Customize the LLM instruction'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: prompt editor
                  },
                ),
                const Divider(),

                // --- Privacy ---
                _buildSectionHeader(context, 'Privacy'),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Notice'),
                  subtitle: const Text('Data stays local, no internet calls'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPrivacyNotice(context),
                ),
                const Divider(),

                // --- App Info ---
                _buildSectionHeader(context, 'About'),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  subtitle: Text('1.0.0'),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Notice'),
        content: const SingleChildScrollView(
          child: Text(
            'This app runs entirely offline. No data is sent to any server.\n\n'
            'All conversations and hexagram data are stored locally on your '
            'device using SQLite. The AI model runs on-device '
            'via flutter_gemma.\n\n'
            'No internet connection is required after the initial model '
            'download. Your privacy is fully protected.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
