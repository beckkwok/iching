import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
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

/// Material fallback icons (used when Rive animations are disabled).
const List<IconData> _fallbackIcons = [
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
  /// Whether to render the Rive-animated navigation icons.
  ///
  /// Disabled on Windows (the Rive runtime crashes there) and in widget tests
  /// (no Rive native library) — a plain Material icon is used instead. Rive is
  /// used on Android/iOS.
  static bool enableRiveAnimations =
      !kIsWeb && defaultTargetPlatform != TargetPlatform.windows;

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
  final List<Widget?> _tabs = List<Widget?>.filled(_navItems.length, null);

  File? _riveFile;
  final List<RiveWidgetController?> _navControllers =
      List<RiveWidgetController?>.filled(_navItems.length, null);

  @override
  void initState() {
    super.initState();
    if (HomeShell.enableRiveAnimations) _loadRive();
  }

  Future<void> _loadRive() async {
    File? file;
    try {
      file = await File.asset(
        'assets/RiveAssets/icons.riv',
        riveFactory: Factory.rive,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Rive load failed: $e');
      return;
    }
    if (file == null || !mounted) return;
    for (var i = 0; i < _navItems.length; i++) {
      try {
        _navControllers[i] = RiveWidgetController(
          file,
          artboardSelector: ArtboardNamed(_navItems[i].artboard),
          stateMachineSelector: StateMachineNamed(_navItems[i].machine),
        );
      } catch (_) {
        // Artboard/state machine missing — the fallback icon is used.
      }
    }
    if (mounted) setState(() => _riveFile = file);
  }

  @override
  void dispose() {
    for (final controller in _navControllers) {
      controller?.dispose();
    }
    _riveFile?.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i != _index) setState(() => _index = i);
    final input = _navControllers[i]?.stateMachine.boolean('active');
    if (input != null) {
      input.value = true;
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) input.value = false;
      });
    }
  }

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
                controller: _navControllers[i],
                fallbackIcon: _fallbackIcons[i],
                active: _index == i,
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
  final RiveWidgetController? controller;
  final IconData fallbackIcon;
  final bool active;

  const _RiveNavIcon({
    required this.controller,
    required this.fallbackIcon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) return Icon(fallbackIcon, size: 22);
    return SizedBox(
      height: 26,
      width: 26,
      child: Opacity(
        opacity: active ? 1 : 0.55,
        child: RiveWidget(controller: controller, fit: Fit.contain),
      ),
    );
  }
}
