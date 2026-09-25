import 'package:flutter/material.dart';

/// A primary action button filled with a deep-purple gradient.
///
/// Used in place of [FilledButton] for primary calls-to-action across the app.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  });

  final VoidCallback? onPressed;

  /// The text shown inside the button.
  final String label;

  /// An optional leading widget (an [Icon] or a loading spinner).
  final Widget? icon;

  static const Color start = Color(0xFF673AB7);
  static const Color end = Color(0xFFAB47BC);

  /// Gold glow colour for the button's outer shadow.
  static const Color glow = Color(0xFFD4AF37);

  /// The glow's blur and spread radii.
  static const double glowBlurRadius = 24;
  static const double glowSpreadRadius = 2;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [start, end],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: 0.5),
                blurRadius: glowBlurRadius,
                spreadRadius: glowSpreadRadius,
              ),
            ],
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(24),
            child: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  child: Center(child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
