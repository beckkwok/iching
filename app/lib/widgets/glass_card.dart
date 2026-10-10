import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted-glass container per the #60 spec: backdrop blur, obsidian fill at
/// 0.6 in dark mode / opaque parchment in light mode, hairline gold-bronze
/// border and a large radius.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(24);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF13131A).withValues(alpha: 0.6)
                : const Color(0xFFF9F6EE),
            borderRadius: radius,
            border: Border.all(
              color: isDark
                  ? const Color(0xFFE6D5B8).withValues(alpha: 0.3)
                  : const Color(0xFFC5B358),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
