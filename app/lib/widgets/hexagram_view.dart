import 'package:flutter/material.dart';

/// Renders a hexagram as six stacked yao lines, bottom (index 0) to top.
///
/// Each element of [lines] is `true` for a yang (solid) line or `false` for a
/// yin (broken) line. The bars are deliberately narrow and the gaps tall so
/// the whole figure is **taller than it is wide** — a hexagram is a vertical
/// figure, not a wide one.
class HexagramView extends StatelessWidget {
  /// The six lines, bottom (index 0) to top (index 5).
  final List<bool> lines;

  /// Width of the bars.
  final double width;

  /// Thickness of each bar.
  final double lineHeight;

  /// Vertical gap between bars.
  final double gap;

  /// Corner radius of each bar.
  final double radius;

  const HexagramView({
    super.key,
    required this.lines,
    this.width = 72,
    this.lineHeight = 9,
    this.gap = 6,
    this.radius = 2,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = lines.length - 1; i >= 0; i--) ...[
            if (i != lines.length - 1) SizedBox(height: gap),
            _YaoBar(
              isYang: lines[i],
              color: color,
              height: lineHeight,
              radius: radius,
            ),
          ],
        ],
      ),
    );
  }
}

/// A single yao bar: solid (yang) or broken into two segments (yin).
class _YaoBar extends StatelessWidget {
  final bool isYang;
  final Color color;
  final double height;
  final double radius;

  const _YaoBar({
    required this.isYang,
    required this.color,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    if (isYang) return _bar();
    // Yin (broken) line: two bars separated by a gap.
    return Row(
      children: [
        Expanded(child: _bar()),
        SizedBox(width: height * 1.6),
        Expanded(child: _bar()),
      ],
    );
  }

  Widget _bar() => Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
