import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Frosted-glass container per the #60 spec: backdrop blur, obsidian fill at
/// 0.6 in dark mode / opaque parchment in light mode, crisp champagne border
/// with a layered outer glow, subtle inner luminosity, and a large radius.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(24);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: champagneGold.withValues(alpha: 0.35),
            blurRadius: 12,
          ),
          BoxShadow(
            color: champagneGold.withValues(alpha: 0.15),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1E1E28).withValues(alpha: 0.6),
                        const Color(0xFF13131A).withValues(alpha: 0.6),
                      ]
                    : [Colors.white, const Color(0xFFF9F6EE)],
              ),
              borderRadius: radius,
              border: Border.all(
                color: isDark
                    ? champagneGold.withValues(alpha: 0.45)
                    : bronzeGold,
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
