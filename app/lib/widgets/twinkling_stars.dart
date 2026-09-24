import 'dart:math' as math;

import 'package:flutter/material.dart';

/// An animated field of twinkling stars on a black sky.
///
/// Used as the immersive background of the first (Ask) screen in dark mode.
class TwinklingStars extends StatefulWidget {
  const TwinklingStars({super.key, this.starCount = 60});

  /// Number of stars to render.
  final int starCount;

  @override
  State<TwinklingStars> createState() => _TwinklingStarsState();
}

class _TwinklingStarsState extends State<TwinklingStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _stars = _generateStars(widget.starCount);
  }

  List<_Star> _generateStars(int count) {
    final random = math.Random();
    return List.generate(count, (_) {
      return _Star(
        position: Offset(random.nextDouble(), random.nextDouble()),
        radius: 0.6 + random.nextDouble() * 1.4,
        phase: random.nextDouble() * 2 * math.pi,
        speed: 0.4 + random.nextDouble() * 1.6,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _StarPainter(stars: _stars, progress: _controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Star {
  const _Star({
    required this.position,
    required this.radius,
    required this.phase,
    required this.speed,
  });

  /// Position as a fraction of the canvas (0..1 in both axes).
  final Offset position;
  final double radius;
  final double phase;
  final double speed;
}

class _StarPainter extends CustomPainter {
  _StarPainter({required this.stars, required this.progress});

  final List<_Star> stars;

  /// Animation progress in [0, 1), drives each star's twinkle.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    final paint = Paint();
    for (final star in stars) {
      final twinkle =
          (math.sin(progress * 2 * math.pi * star.speed + star.phase) + 1) / 2;
      paint.color = Color.fromRGBO(255, 255, 255, 0.15 + 0.85 * twinkle);
      final center = Offset(
        star.position.dx * size.width,
        star.position.dy * size.height,
      );
      canvas.drawCircle(center, star.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.stars != stars;
}
