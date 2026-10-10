import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A primary action button with a solid, celestial gold fill.
///
/// Both themes use the same rich-gold gradient (champagne [start] → deeper
/// bronze [end]) with dark [ink] label/icons, so the CTA stays a bright focal
/// point against either backdrop. A soft gold glow surrounds it. Pressing it
/// scales the button down slightly and triggers a light haptic.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.gradientColors,
    this.foregroundColor = ink,
  });

  final VoidCallback? onPressed;

  /// The text shown inside the button.
  final String label;

  /// An optional leading widget (an [Icon] or a loading spinner).
  final Widget? icon;

  /// Optional gradient fill override. Defaults to the champagne [start] →
  /// deeper bronze [end] gradient.
  final List<Color>? gradientColors;

  /// Color of the label, icon and spinner. Defaults to [ink] for contrast on
  /// the gold fill.
  final Color foregroundColor;

  static const Color start = Color(0xFFE6D5B8); // champagne gold
  static const Color end = Color(0xFFC5B358); // deeper bronze

  /// Gold used for the button's glow.
  static const Color gold = Color(0xFFE6D5B8);

  /// Dark ink used for the label and icons on the gold fill (issue #73).
  static const Color ink = Color(0xFF13131A);

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

  BoxDecoration _decoration() {
    final radius = BorderRadius.circular(24);
    final custom = widget.gradientColors;
    return BoxDecoration(
      gradient: LinearGradient(
        colors: custom ?? const [GradientButton.start, GradientButton.end],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: radius,
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
          style: TextStyle(
            color: widget.foregroundColor,
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
            decoration: _decoration(),
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
                data: IconThemeData(
                    color: widget.foregroundColor, size: 18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      widthFactor: 1,
                      heightFactor: 1,
                      child: content,
                    ),
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
