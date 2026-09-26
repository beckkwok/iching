import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A primary action button with an immersive, "glowing jade" look.
///
/// In dark mode it uses a translucent deep-purple fill (so the star background
/// shows through), a fine gold border, and a soft gold glow. In light mode it
/// falls back to the solid purple gradient for contrast. Pressing it scales the
/// button down slightly and triggers a light haptic.
class GradientButton extends StatefulWidget {
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

  /// Gold used for the button's border and glow.
  static const Color gold = Color(0xFFD4AF37);

  /// The glow's blur and spread radii.
  static const double glowBlurRadius = 24;
  static const double glowSpreadRadius = 2;

  /// How much the button shrinks while pressed.
  static const double pressedScale = 0.95;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  BoxDecoration _decoration(bool isDark) {
    final radius = BorderRadius.circular(24);
    if (!isDark) {
      return BoxDecoration(
        gradient: const LinearGradient(
          colors: [GradientButton.start, GradientButton.end],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
      );
    }

    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          GradientButton.start.withValues(alpha: 0.35),
          GradientButton.end.withValues(alpha: 0.22),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: radius,
      border: Border.all(
        color: GradientButton.gold.withValues(alpha: 0.55),
      ),
      boxShadow: [
        BoxShadow(
          color: GradientButton.gold.withValues(alpha: 0.5),
          blurRadius: GradientButton.glowBlurRadius,
          spreadRadius: GradientButton.glowSpreadRadius,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(24);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
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
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _pressed ? GradientButton.pressedScale : 1,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: _decoration(isDark),
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: radius,
              onTapDown: enabled
                  ? (_) {
                      HapticFeedback.lightImpact();
                      _setPressed(true);
                    }
                  : null,
              onTapUp: enabled ? (_) => _setPressed(false) : null,
              onTapCancel: enabled ? () => _setPressed(false) : null,
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
      ),
    );
  }
}
