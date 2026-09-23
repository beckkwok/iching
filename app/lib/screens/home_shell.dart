import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../services/llm_service.dart';
import 'hexagram_browser_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'question_form_screen.dart';
import 'settings_screen.dart';

/// Icons for the five bottom-nav destinations, in order:
/// History, Profile, Ask, Browse, Preference.
const List<IconData> _navIcons = [
  Icons.history,
  Icons.person_outline,
  Icons.question_answer_outlined,
  Icons.grid_view_outlined,
  Icons.tune,
];

/// The app shell: a bottom navigation bar hosting the five top-level tabs.
///
/// The header bar was intentionally removed as part of the mobile redesign
/// (issue #6).
class HomeShell extends StatefulWidget {
  final DatabaseService? databaseService;
  final LlmService? llmService;

  /// Tab shown initially (defaults to Ask).
  final int initialIndex;

  const HomeShell({
    super.key,
    required this.databaseService,
    this.llmService,
    this.initialIndex = 2,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  /// Lazily-built tabs, kept alive once visited.
  final List<Widget?> _tabs = List<Widget?>.filled(_navIcons.length, null);

  void _select(int i) {
    if (i != _index) setState(() => _index = i);
  }

  Widget _buildTab(int i) => switch (i) {
        0 => const HistoryScreen(),
        1 => const ProfileScreen(),
        2 => QuestionFormScreen(
            databaseService: widget.databaseService,
            llmService: widget.llmService,
          ),
        3 => HexagramBrowserScreen(databaseService: widget.databaseService),
        _ => SettingsScreen(
            databaseService: widget.databaseService,
            llmService: widget.llmService,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.navHistory,
      l10n.navProfile,
      l10n.navAsk,
      l10n.navBrowse,
      l10n.navPreference,
    ];

    // Build the active tab on first visit; previously-visited tabs stay alive.
    _tabs[_index] ??= _buildTab(_index);
    final tabs = <Widget>[
      for (var i = 0; i < _navIcons.length; i++)
        _tabs[i] ?? const SizedBox.shrink(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: FBottomNavigationBar(
        index: _index,
        onChange: _select,
        children: [
          for (var i = 0; i < _navIcons.length; i++)
            FBottomNavigationBarItem(
              icon: _NavIcon(icon: _navIcons[i], active: _index == i),
              label: Text(labels[i]),
            ),
        ],
      ),
    );
  }
}

/// A bottom-nav icon that scales up and tints when it is the active tab.
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _NavIcon({required this.icon, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: active ? 1.25 : 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Icon(icon, size: 22, color: color),
    );
  }
}
