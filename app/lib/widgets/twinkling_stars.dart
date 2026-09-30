import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// An animated field of twinkling stars (and occasional meteors) on a dark sky.
///
/// Used as the immersive background of the app's tabs in dark mode.
class TwinklingStars extends StatefulWidget {
  const TwinklingStars({
    super.key,
    this.starCount = 60,
    this.meteorCount = 3,
  });

  /// The sky's background gradient — deepest at the top, lifted toward the
  /// bottom, giving the night sky some depth.
  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0B0914),
      Color(0xFF12101E),
      Color(0xFF1D1A33),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Number of stars to render.
  final int starCount;

  /// Number of shooting stars to render.
  final int meteorCount;

  @override
  State<TwinklingStars> createState() => _TwinklingStarsState();
}

class _TwinklingStarsState extends State<TwinklingStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Star> _stars;
  late final List<_Meteor> _meteors;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _stars = _generateStars(widget.starCount);
    _meteors = _generateMeteors(widget.meteorCount);
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

  List<_Meteor> _generateMeteors(int count) {
    final random = math.Random();
    return List.generate(count, (_) {
      // Travel down and to the left, mostly starting in the upper-right.
      final dx = -(0.8 + random.nextDouble() * 0.2);
      final dy = 0.4 + random.nextDouble() * 0.2;
      final length = math.sqrt(dx * dx + dy * dy);
      return _Meteor(
        start: Offset(
          0.3 + random.nextDouble() * 0.9,
          random.nextDouble() * 0.45,
        ),
        direction: Offset(dx / length, dy / length),
        length: 0.12 + random.nextDouble() * 0.08,
        phase: random.nextDouble(),
        speed: 0.25 + random.nextDouble() * 0.35,
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
        painter: _StarPainter(
          stars: _stars,
          meteors: _meteors,
          progress: _controller.value,
        ),
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

class _Meteor {
  const _Meteor({
    required this.start,
    required this.direction,
    required this.length,
    required this.phase,
    required this.speed,
  });

  /// Start position as a fraction of the canvas.
  final Offset start;

  /// Unit direction of travel.
  final Offset direction;

  /// Trail length as a fraction of the canvas width.
  final double length;

  final double phase;
  final double speed;
}

class _StarPainter extends CustomPainter {
  _StarPainter({
    required this.stars,
    required this.meteors,
    required this.progress,
  });

  final List<_Star> stars;
  final List<_Meteor> meteors;

  /// Animation progress in [0, 1), drives each star's twinkle and each
  /// meteor's streak.
  final double progress;

  /// Fraction of the loop during which a meteor is visible.
  static const double _meteorVisible = 0.06;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = TwinklingStars.skyGradient.createShader(rect),
    );

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

    for (final meteor in meteors) {
      final t = (progress * meteor.speed + meteor.phase) % 1.0;
      if (t > _meteorVisible) continue;
      final k = t / _meteorVisible;
      final start = Offset(
        meteor.start.dx * size.width,
        meteor.start.dy * size.height,
      );
      final travel = 0.35 * size.width * k;
      final head = start + meteor.direction * travel;
      final tail = head - meteor.direction * (meteor.length * size.width);
      final alpha = math.sin(math.pi * k).clamp(0.0, 1.0);
      final meteorPaint = Paint()
        ..shader = ui.Gradient.linear(
          tail,
          head,
          [
            const Color(0x00FFFFFF),
            Color.fromRGBO(255, 255, 255, alpha),
          ],
        )
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(tail, head, meteorPaint);
      canvas.drawCircle(
        head,
        1.4,
        Paint()..color = Color.fromRGBO(255, 255, 255, alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.stars != stars ||
      oldDelegate.meteors != meteors;
}
