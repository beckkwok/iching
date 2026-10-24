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

  /// Optional per-line labels, in the same bottom → top order as [lines].
  ///
  /// When provided, each bar is rendered in a row with its label to the right
  /// (e.g. `- - 少陰`).
  final List<String>? labels;

  /// Optional per-line label colors, in the same bottom → top order as
  /// [lines]. Defaults to the theme's `onSurfaceVariant`.
  final List<Color>? labelColors;

  const HexagramView({
    super.key,
    required this.lines,
    this.width = 72,
    this.lineHeight = 9,
    this.gap = 6,
    this.radius = 2,
    this.labels,
    this.labelColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final labels = this.labels;
    final labelColors = this.labelColors;

    return SizedBox(
      width: labels == null ? width : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = lines.length - 1; i >= 0; i--) ...[
            if (i != lines.length - 1) SizedBox(height: gap),
            if (labels == null)
              _YaoBar(
                isYang: lines[i],
                color: color,
                height: lineHeight,
                radius: radius,
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: width,
                    child: _YaoBar(
                      isYang: lines[i],
                      color: color,
                      height: lineHeight,
                      radius: radius,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      color: (i < (labelColors?.length ?? 0))
                          ? labelColors![i]
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
