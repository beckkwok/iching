import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/consultation.dart';
import '../models/gua.dart';
import '../services/database_service.dart';
import 'hexagram_detail_screen.dart';

/// Lists the recorded consultations (question, hexagram, explanation).
///
/// See issue #8.
class HistoryScreen extends StatefulWidget {
  final DatabaseService? databaseService;

  const HistoryScreen({super.key, this.databaseService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Consultation>? _consultations;
  bool _loading = true;

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Run once, after the first build context exists.
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final db = widget.databaseService;
    List<Consultation> items = const [];
    if (db != null) {
      items = await db.getConsultations();
    }
    if (mounted) {
      setState(() {
        _consultations = items;
        _loading = false;
      });
    }
  }

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final consultations = _consultations ?? const <Consultation>[];
    if (consultations.isEmpty) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.historyEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: consultations.length,
        itemBuilder: (context, index) {
          final c = consultations[index];
          return _ConsultationCard(
            consultation: c,
            dateLabel: _formatDate(c.createdAt),
          );
        },
      ),
    );
  }
}

/// A single consultation in the history list.
class _ConsultationCard extends StatelessWidget {
  final Consultation consultation;
  final String dateLabel;

  const _ConsultationCard({
    required this.consultation,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HexagramDetailScreen(
                gua: Gua(
                  guaCode: consultation.hexagramCode,
                  guaName: consultation.hexagramName,
                  guaContent: consultation.hexagramContent,
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      consultation.hexagramName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    l10n.hexagramNumber(consultation.hexagramCode),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                consultation.question,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                consultation.explanation,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (consultation.rating != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= consultation.rating!
                            ? Icons.star
                            : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
                      ),
                  ],
                ),
              ],
              if (consultation.comment != null &&
                  consultation.comment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  consultation.comment!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
