import 'package:flutter/material.dart';
import '../models/gua.dart';
import '../services/database_service.dart';
import 'hexagram_detail_screen.dart';

/// Browse all seeded hexagrams in a 2-column card grid.
///
/// Each card shows the 卦序, 卦象, and 卦名. Tapping a card opens the
/// [HexagramDetailScreen] for that hexagram.
class HexagramBrowserScreen extends StatefulWidget {
  final DatabaseService? databaseService;

  const HexagramBrowserScreen({super.key, required this.databaseService});

  @override
  State<HexagramBrowserScreen> createState() => _HexagramBrowserScreenState();
}

class _HexagramBrowserScreenState extends State<HexagramBrowserScreen> {
  List<Gua>? _guaList;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = widget.databaseService;
    if (db == null) {
      setState(() => _error = 'Database unavailable.');
      return;
    }
    try {
      final guaList = await db.getAllGua();
      // Sort by guaCode for a stable 1..64 ordering.
      guaList.sort((a, b) => a.guaCode.compareTo(b.guaCode));
      if (mounted) setState(() => _guaList = guaList);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load hexagrams: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hexagrams'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
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
      return const Center(
        child: Text(
          'No hexagrams found. Please run the app once to seed them.',
        ),
      );
    }

    return GridView.builder(
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
        return _HexagramTile(gua: gua);
      },
    );
  }
}

/// A single tappable hexagram card in the browse grid.
class _HexagramTile extends StatelessWidget {
  final Gua gua;

  const _HexagramTile({required this.gua});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = gua.content?.guaSymbol ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => HexagramDetailScreen(gua: gua)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 卦序
              Text(
                '第${gua.guaCode}卦',
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
