import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/agent_memory.dart';
import '../models/consultation.dart';
import '../services/database_service.dart';

/// Shows the agent memory: the last consultation and the LLM-derived profile
/// (feeling, facts, preferences). See issue #3.
class ProfileScreen extends StatefulWidget {
  final DatabaseService? databaseService;

  const ProfileScreen({super.key, this.databaseService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AgentMemory? _memory;
  Consultation? _lastConsultation;
  bool _loading = true;

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final db = widget.databaseService;
    if (db != null) {
      _memory = await db.getAgentMemory();
      final consultations = await db.getConsultations();
      if (consultations.isNotEmpty) _lastConsultation = consultations.first;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasMemory = _memory != null && !_memory!.isEmpty;
    if (_lastConsultation == null && !hasMemory) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.memoryEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_lastConsultation != null) ...[
            _card(
              theme,
              title: l10n.lastConsultation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lastConsultation!.hexagramName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lastConsultation!.question,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
          if (hasMemory) ...[
            _card(
              theme,
              title: l10n.memoryTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_memory!.feeling.isNotEmpty) ...[
                    _sectionTitle(theme, l10n.memoryFeeling),
                    Text(_memory!.feeling, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                  ],
                  if (_memory!.facts.isNotEmpty) ...[
                    _sectionTitle(theme, l10n.memoryFacts),
                    ..._memory!.facts.map((f) => _bullet(theme, f)),
                    const SizedBox(height: 12),
                  ],
                  if (_memory!.preferences.isNotEmpty) ...[
                    _sectionTitle(theme, l10n.memoryPreferences),
                    ..._memory!.preferences.map((p) => _bullet(theme, p)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card(ThemeData theme, {required String title, required Widget child}) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _bullet(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• '),
            Expanded(
              child: Text(text, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      );
}
