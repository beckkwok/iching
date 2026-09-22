import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:rive/rive.dart';

import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../services/llm_service.dart';
import 'hexagram_browser_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'question_form_screen.dart';
import 'settings_screen.dart';

/// The bottom-nav destinations, in order: History, Profile, Ask, Browse,
/// Preference. Each maps to an artboard/state machine in `icons.riv`.
const List<({String artboard, String machine})> _navItems = [
  (artboard: 'TIMER', machine: 'TIMER_Interactivity'),
  (artboard: 'USER', machine: 'USER_Interactivity'),
  (artboard: 'CHAT', machine: 'CHAT_Interactivity'),
  (artboard: 'SEARCH', machine: 'SEARCH_Interactivity'),
  (artboard: 'HOME', machine: 'HOME_interactivity'),
];

/// The app shell: a bottom navigation bar hosting the five top-level tabs.
///
/// The header bar was intentionally removed as part of the mobile redesign
/// (issue #6).
class HomeShell extends StatefulWidget {
  /// Whether to render the Rive-animated navigation icons.
  ///
  /// Disabled in widget tests, where the Rive native library isn't available
  /// (a plain Material icon is used instead).
  static bool enableRiveAnimations = true;

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
  final List<SMIBool?> _navInputs =
      List<SMIBool?>.filled(_navItems.length, null);

  /// Lazily-built tabs, kept alive once visited.
  final List<Widget?> _tabs = List<Widget?>.filled(_navItems.length, null);

  Widget _buildTab(int i) => switch (i) {
        0 => const HistoryScreen(),
        1 => const ProfileScreen(),
        2 => QuestionFormScreen(
            databaseService: widget.databaseService,
            llmService: widget.llmService,
          ),
        3 => const HexagramBrowserScreen(),
        _ => SettingsScreen(
            databaseService: widget.databaseService,
            llmService: widget.llmService,
          ),
      };

  void _onNavInit(int i, Artboard artboard) {
    final controller =
        StateMachineController.fromArtboard(artboard, _navItems[i].machine);
    if (controller == null) return;
    artboard.addController(controller);
    _navInputs[i] = controller.findInput<bool>('active') as SMIBool?;
  }

  void _select(int i) {
    if (i != _index) setState(() => _index = i);
    final input = _navInputs[i];
    if (input != null) {
      input.change(true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) input.change(false);
      });
    }
  }

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
      for (var i = 0; i < _navItems.length; i++)
        _tabs[i] ?? const SizedBox.shrink(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: FBottomNavigationBar(
        index: _index,
        onChange: _select,
        children: [
          for (var i = 0; i < _navItems.length; i++)
            FBottomNavigationBarItem(
              icon: _RiveNavIcon(
                artboard: _navItems[i].artboard,
                active: _index == i,
                onInit: (artboard) => _onNavInit(i, artboard),
              ),
              label: Text(labels[i]),
            ),
        ],
      ),
    );
  }
}

/// A Rive-animated navigation icon from `assets/RiveAssets/icons.riv`.
class _RiveNavIcon extends StatelessWidget {
  final String artboard;
  final bool active;
  final ValueChanged<Artboard> onInit;

  const _RiveNavIcon({
    required this.artboard,
    required this.active,
    required this.onInit,
  });

  @override
  Widget build(BuildContext context) {
    if (!HomeShell.enableRiveAnimations) {
      return Icon(_fallbackIcon, size: 22);
    }
    return SizedBox(
      height: 26,
      width: 26,
      child: Opacity(
        opacity: active ? 1 : 0.55,
        child: RiveAnimation.asset(
          'assets/RiveAssets/icons.riv',
          artboard: artboard,
          onInit: onInit,
        ),
      ),
    );
  }

  /// Material fallback used when Rive animations are disabled (tests).
  IconData get _fallbackIcon => switch (artboard) {
        'TIMER' => Icons.history,
        'USER' => Icons.person_outline,
        'CHAT' => Icons.question_answer_outlined,
        'SEARCH' => Icons.grid_view_outlined,
        _ => Icons.tune,
      };
}
