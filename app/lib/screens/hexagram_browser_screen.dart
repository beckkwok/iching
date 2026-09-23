import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/gua.dart';
import '../services/database_service.dart';
import '../services/hexagram_loader.dart';
import 'hexagram_detail_screen.dart';

/// Settings key under which the most recently visited hexagram code is stored.
const String lastVisitedGuaSettingsKey = 'last_visited_gua';

/// Browse all hexagrams in a 2-column card grid.
///
/// Each card shows the 卦序, 卦象, and 卦名. Tapping a card opens the
/// [HexagramDetailScreen] for that hexagram. The most recently visited
/// hexagram is shown in a header above the grid (issue #11).
class HexagramBrowserScreen extends StatefulWidget {
  /// Optional loader for tests. When omitted, the bundled JSON assets are used.
  final HexagramLoader? loader;

  /// Used to persist the last visited hexagram. When omitted, the last visited
  /// hexagram is only kept for the current session.
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
  Gua? _lastVisited;
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
          ?.getSetting(lastVisitedGuaSettingsKey);
      final lastCode = int.tryParse(saved ?? '');
      Gua? lastVisited;
      if (lastCode != null) {
        for (final gua in guaList) {
          if (gua.guaCode == lastCode) {
            lastVisited = gua;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _guaList = guaList;
          _lastVisited = lastVisited;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load hexagrams: $e');
    }
  }

  Future<void> _openGua(Gua gua) async {
    // Record it as the last visited hexagram.
    await widget.databaseService
        ?.setSetting(lastVisitedGuaSettingsKey, gua.guaCode.toString());
    if (mounted) setState(() => _lastVisited = gua);
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
        if (_lastVisited != null)
          _LastVisitedHeader(
            gua: _lastVisited!,
            onTap: () => _openGua(_lastVisited!),
          ),
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

/// Header card showing the most recently visited hexagram.
class _LastVisitedHeader extends StatelessWidget {
  final Gua gua;
  final VoidCallback onTap;

  const _LastVisitedHeader({required this.gua, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final symbol = gua.content?.guaSymbol ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (symbol.isNotEmpty)
                Text(symbol, style: theme.textTheme.titleMedium)
              else
                const Icon(Icons.auto_awesome),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.lastVisited,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gua.guaName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
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
