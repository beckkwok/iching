import 'package:flutter/material.dart';

/// Settings screen accessible from the chat screen's header menu.
///
/// Sub-sections to be implemented:
/// - Model path & model selection
/// - Prompt settings (system prompt customization)
/// - Privacy notice
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          // --- Model ---
          _buildSectionHeader(context, 'Model'),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Model Path'),
            subtitle: const Text('Qwen3-0.6B.litertlm'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: model file picker
            },
          ),
          ListTile(
            leading: const Icon(Icons.model_training),
            title: const Text('Model Selection'),
            subtitle: const Text('Qwen3 0.6B'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: model selection screen or dialog
            },
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
            onTap: () {
              _showPrivacyNotice(context);
            },
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
            'device using SQLite. The AI model (Qwen3 0.6B) runs on-device '
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
