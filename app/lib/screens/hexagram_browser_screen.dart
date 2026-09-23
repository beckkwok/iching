import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/gua.dart';
import '../services/database_service.dart';
import '../services/hexagram_loader.dart';
import 'hexagram_detail_screen.dart';

/// Settings key under which the recently visited hexagram codes are stored
/// (comma-separated, most recent first, up to 3).
const String lastVisitedGuasSettingsKey = 'last_visited_guas';

/// How many recently visited hexagrams to keep and display.
const int _maxRecent = 3;

/// Browse all hexagrams in a 2-column card grid.
///
/// Each card shows the 卦序, 卦象, and 卦名. Tapping a card opens the
/// [HexagramDetailScreen] for that hexagram. The most recently visited
/// hexagrams (up to three) are shown in a header above the grid (issue #11).
class HexagramBrowserScreen extends StatefulWidget {
  /// Optional loader for tests. When omitted, the bundled JSON assets are used.
  final HexagramLoader? loader;

  /// Used to persist the recently visited hexagrams. When omitted, they are
  /// only kept for the current session.
  final DatabaseService? databaseService;

  const HexagramBrowserScreen({
    super.key,
    this.loader,
    this.databaseService,
  });

  @override
  State<HexagramBrowserScreen> createState() => _HexagramBrowserScreenState();
}

class _HexagramBrowserScreenState extends State<HexagramBrowserScreen> {
  List<Gua>? _guaList;
  List<Gua> _recent = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final guaList = await (widget.loader ?? HexagramLoader()).loadAll();
      // Sort by guaCode for a stable 1..64 ordering.
      guaList.sort((a, b) => a.guaCode.compareTo(b.guaCode));

      final saved = await widget.databaseService
          ?.getSetting(lastVisitedGuasSettingsKey);
      final codes = (saved ?? '')
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList();
      final recent = <Gua>[];
      for (final code in codes) {
        for (final gua in guaList) {
          if (gua.guaCode == code) {
            recent.add(gua);
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _guaList = guaList;
          _recent = recent;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load hexagrams: $e');
    }
  }

  Future<void> _openGua(Gua gua) async {
    // Prepend to the recent list, de-duplicating, and keep the last 3.
    final recent = [
      gua,
      ..._recent.where((g) => g.guaCode != gua.guaCode),
    ].take(_maxRecent).toList();

    await widget.databaseService?.setSetting(
      lastVisitedGuasSettingsKey,
      recent.map((g) => g.guaCode).join(','),
    );
    if (mounted) setState(() => _recent = recent);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HexagramDetailScreen(gua: gua)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_guaList == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_guaList!.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).noHexagrams),
      );
    }

    return Column(
      children: [
        if (_recent.isNotEmpty)
          _RecentHeader(guas: _recent, onTap: _openGua),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            // Fill the available width: as many columns as fit each ~180px tile.
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: _guaList!.length,
            itemBuilder: (context, index) {
              final gua = _guaList![index];
              return _HexagramTile(
                gua: gua,
                onTap: () => _openGua(gua),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Header showing the recently visited hexagrams (up to three).
class _RecentHeader extends StatelessWidget {
  final List<Gua> guas;
  final void Function(Gua) onTap;

  const _RecentHeader({required this.guas, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
              l10n.recentlyViewed,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final gua in guas)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _RecentChip(gua: gua, onTap: () => onTap(gua)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A single tappable recently-viewed hexagram chip.
class _RecentChip extends StatelessWidget {
  final Gua gua;
  final VoidCallback onTap;

  const _RecentChip({required this.gua, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = gua.content?.guaSymbol ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            if (symbol.isNotEmpty)
              Text(symbol, style: theme.textTheme.titleMedium)
            else
              const Icon(Icons.auto_awesome, size: 20),
            const SizedBox(height: 4),
            Text(
              gua.guaName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single tappable hexagram card in the browse grid.
class _HexagramTile extends StatelessWidget {
  final Gua gua;
  final VoidCallback onTap;

  const _HexagramTile({required this.gua, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final symbol = gua.content?.guaSymbol ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 卦序
              Text(
                l10n.hexagramNumber(gua.guaCode),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // 卦象
              if (symbol.isNotEmpty)
                Text(
                  symbol,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                )
              else
                const Icon(Icons.auto_awesome, size: 28),
              const SizedBox(height: 8),
              // 卦名
              Text(
                gua.guaName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
