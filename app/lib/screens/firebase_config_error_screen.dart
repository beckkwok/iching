import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Shown on Android when Firebase is enabled but the build has no Firebase
/// config (issue #86).
///
/// Build/run with `--dart-define-from-file=firebase.local.json`; see
/// `docs/firebase-setup.md`.
class FirebaseConfigErrorScreen extends StatelessWidget {
  const FirebaseConfigErrorScreen({super.key});

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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 56,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.firebaseConfigErrorTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.firebaseConfigErrorBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
