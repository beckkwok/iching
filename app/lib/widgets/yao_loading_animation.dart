import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/trigram_hexagram_data.dart';

/// An immersive loading indicator: six yao lines morphing between yin and yang
/// with independent random timing, above a loading message and a hexagram name
/// that fades from one to the next (issue #29).
///
/// Each line oscillates `yin -> yang -> yin` on a sine wave; the per-line phase
/// and speed are randomised so the six lines appear to load independently.
class YaoLoadingAnimation extends StatefulWidget {
  /// The status message shown under the yao lines (e.g. "Loading model...").
  final String message;

  /// Names cycled under the message. Defaults to the 64 classical hexagram
  /// names from [TrigramHexagramData].
  final List<String>? hexagramNames;

  /// How long the name stays before fading to the next one.
  final Duration nameInterval;

  /// Width of the figure.
  final double width;

  /// Thickness of each yao bar.
  final double lineHeight;

  /// Vertical gap between the six bars.
  final double gap;

  /// Corner radius of each bar.
  final double radius;

  /// Duration of one yin↔yang cycle.
  final Duration cycleDuration;

  /// Number of lines in the figure.
  static const int lineCount = 6;

  const YaoLoadingAnimation({
    super.key,
    required this.message,
    this.hexagramNames,
    this.nameInterval = const Duration(milliseconds: 1600),
    this.width = 88,
    this.lineHeight = 10,
    this.gap = 8,
    this.radius = 2,
    this.cycleDuration = const Duration(milliseconds: 1400),
  });

  @override
  State<YaoLoadingAnimation> createState() => _YaoLoadingAnimationState();
}

class _YaoLoadingAnimationState extends State<YaoLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<double> _phases;
  late final List<double> _speeds;
  late final List<String> _names;

  Timer? _nameTimer;
  int _nameIndex = 0;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _phases = List.generate(YaoLoadingAnimation.lineCount, (_) => random.nextDouble());
    _speeds = List.generate(
      YaoLoadingAnimation.lineCount,
      (_) => 0.6 + random.nextDouble() * 0.8,
    );
    _names = (widget.hexagramNames == null || widget.hexagramNames!.isEmpty)
        ? [for (final h in TrigramHexagramData.all) h.resultName]
        : widget.hexagramNames!;

    _controller = AnimationController(
      vsync: this,
      duration: widget.cycleDuration,
    )..repeat();

    if (_names.length > 1) {
      _nameTimer = Timer.periodic(widget.nameInterval, (_) {
        if (!mounted) return;
        setState(() => _nameIndex = (_nameIndex + 1) % _names.length);
      });
    }
  }

  @override
  void dispose() {
    _nameTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = YaoLoadingAnimation.lineCount - 1; i >= 0; i--) ...[
                if (i != YaoLoadingAnimation.lineCount - 1)
                  SizedBox(height: widget.gap),
                _AnimatedYao(
                  key: ValueKey('yao-line-$i'),
                  controller: _controller,
                  phase: _phases[i],
                  speed: _speeds[i],
                  color: color,
                  height: widget.lineHeight,
                  radius: widget.radius,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          widget.message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: Text(
            _names[_nameIndex],
            key: ValueKey('yao-name-$_nameIndex'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

/// A single yao bar animating between yang (solid) and yin (two segments).
class _AnimatedYao extends StatelessWidget {
  final AnimationController controller;
  final double phase;
  final double speed;
  final Color color;
  final double height;
  final double radius;

  const _AnimatedYao({
    super.key,
    required this.controller,
    required this.phase,
    required this.speed,
    required this.color,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final maxGap = height * 1.6;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = (controller.value * speed + phase) % 1.0;
        // 0 at yang, 1 at yin — a smooth yin -> yang -> yin oscillation.
        final fraction = (1 - math.cos(t * 2 * math.pi)) / 2;
        return Row(
          children: [
            Expanded(child: _bar()),
            SizedBox(width: fraction * maxGap),
            Expanded(child: _bar()),
          ],
        );
      },
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
