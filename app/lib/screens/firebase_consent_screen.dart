import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../services/llm_service.dart';
import '../widgets/gradient_button.dart';
import 'home_shell.dart';

/// First-run consent for sending the question + hexagram to the remote LLM
/// provider (issue #86).
///
/// Shown only on the Android remote edition. Once accepted, the choice is
/// stored in `settings` and the app opens [HomeShell].
class FirebaseConsentScreen extends StatelessWidget {
  final DatabaseService? databaseService;
  final LlmService? llmService;

  const FirebaseConsentScreen({
    super.key,
    this.databaseService,
    this.llmService,
  });

  Future<void> _accept(BuildContext context) async {
    await databaseService?.setSetting(AppConfig.firebaseConsentKey, 'true');
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            HomeShell(databaseService: databaseService, llmService: llmService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.cloud_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.firebaseConsentTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.firebaseConsentBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const Spacer(),
              SizedBox(
                height: 48,
                child: GradientButton(
                  onPressed: () => _accept(context),
                  icon: const Icon(Icons.check),
                  label: l10n.firebaseConsentAgree,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
