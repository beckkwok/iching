import 'dart:io';
import 'package:flutter/material.dart';
import '../services/llm_service.dart';

/// Settings screen accessible from the chat screen's header menu.
class SettingsScreen extends StatefulWidget {
  final LlmService? llmService;

  const SettingsScreen({super.key, this.llmService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _modelFilename = 'Loading...';
  String _modelFullPath = 'Loading...';
  bool _loading = true;
  bool _isValidating = false;
  String? _validationResult;

  @override
  void initState() {
    super.initState();
    _loadModelInfo();
  }

  Future<void> _loadModelInfo() async {
    final svc = widget.llmService;
    if (svc == null) {
      setState(() {
        _modelFilename = 'No LLM service';
        _modelFullPath = 'Not available';
        _loading = false;
      });
      return;
    }
    try {
      final path = await svc.modelFilePath;
      if (mounted) {
        setState(() {
          _modelFilename = svc.modelFilename;
          _modelFullPath = path;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _modelFilename = 'Error';
          _modelFullPath = '$e';
          _loading = false;
        });
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
                  title: const Text('Model File'),
                  subtitle: Text(
                    _modelFilename,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickModelFile(),
                ),
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: const Text('Full Path'),
                  subtitle: Text(
                    _modelFullPath,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
                if (_validationResult != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _validationResult!.startsWith('✅')
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _validationResult!.startsWith('✅')
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _validationResult!.startsWith('✅')
                                ? Icons.check_circle
                                : Icons.error,
                            color: _validationResult!.startsWith('✅')
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _validationResult!,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: OutlinedButton.icon(
                    onPressed: _isValidating ? null : _validateModel,
                    icon: _isValidating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_isValidating
                        ? 'Validating...'
                        : 'Test & Validate Model'),
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

  // ---------------------------------------------------------------------------
  // Model file selection & validation
  // ---------------------------------------------------------------------------

  Future<void> _pickModelFile() async {
    // TODO: Integrate file_picker package to browse for .litertlm / .task files
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File picker not yet implemented. '
            'Will allow selecting .litertlm / .task files.'),
      ),
    );
  }

  Future<void> _validateModel() async {
    final svc = widget.llmService;
    if (svc == null) return;

    setState(() {
      _isValidating = true;
      _validationResult = null;
    });

    try {
      // Check if file exists
      final path = await svc.modelFilePath;
      final file = File(path);
      if (!await file.exists()) {
        setState(() {
          _isValidating = false;
          _validationResult = '❌ Model file not found at: $path';
        });
        return;
      }

      // Check file size
      final size = await file.length();
      if (size < 1024 * 1024) {
        setState(() {
          _isValidating = false;
          _validationResult = '❌ Model file is too small (${_formatSize(size)}). '
              'May be corrupted.';
        });
        return;
      }

      // Try to register and load the model
      await svc.closeChat();
      await svc.openChat();

      setState(() {
        _isValidating = false;
        _validationResult = '✅ Model validated successfully! '
            '(${_formatSize(size)} — ${svc.modelFilename})';
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
        _validationResult = '❌ Validation failed: $e';
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
