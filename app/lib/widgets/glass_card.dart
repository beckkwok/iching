import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted-glass container: backdrop blur, translucent fill, hairline border
/// and a large radius (issue #60). Adapts to both themes via the color scheme.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(24);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.35),
            borderRadius: radius,
            border: Border.all(
              color:
                  theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
