import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadarTarget {
  final double angle; // 0-360°
  final double distance; // 0-1
  final Color color;
  RadarTarget({required this.angle, required this.distance, this.color = Colors.cyan});
}

class RadarScope extends StatefulWidget {
  final List<RadarTarget> targets;
  final double size;
  final Duration sweepDuration;
  const RadarScope({
    super.key,
    this.targets = const [],
    this.size = 300,
    this.sweepDuration = const Duration(seconds: 3),
  });

  @override
  State<RadarScope> createState() => _RadarScopeState();
}

class _RadarScopeState extends State<RadarScope> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sweepAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.sweepDuration, vsync: this)..repeat();
    _sweepAnimation = Tween(begin: 0.0, end: 2 * math.pi).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: widget.size, height: widget.size, child: AnimatedBuilder(
      animation: _sweepAnimation,
      builder: (context, child) => CustomPaint(size: Size.square(widget.size), painter: RadarPainter(_sweepAnimation.value, widget.targets)),
    ));
  }
}

class RadarPainter extends CustomPainter {
  final double sweepAngle;
  final List<RadarTarget> targets;
  RadarPainter(this.sweepAngle, this.targets);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background
    canvas.drawCircle(center, radius, Paint()..color = Colors.black);

    // Grids & spokes (unchanged)
    final gridPaint = Paint()..color = Colors.green.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1;
    for (int i = 1; i <= 5; i++) canvas.drawCircle(center, radius * i / 5, gridPaint);
    final spokePaint = Paint()..color = Colors.green.withOpacity(0.2)..strokeWidth = 1;
    for (int i = 0; i < 12; i++) {
      final angle = 2 * math.pi * i / 12;
      canvas.drawLine(center, Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)), spokePaint);
    }
    canvas.drawCircle(center, 4, Paint()..color = Colors.green);

    // Fading trail - draw filled wedge segments
    final trailLength = 2 * math.pi; // Full circle coverage
    final segments = 60;
    final segmentSize = trailLength / segments;
    for (int i = 0; i < segments; i++) {
      final segmentAngle = sweepAngle - (segmentSize * i);
      final normalizedDist = i / segments.toDouble();
      final opacity = (1.0 - normalizedDist) * 0.3;
      if (opacity > 0.01) {
        final paint = Paint()
          ..color = Colors.green.withOpacity(opacity)
          ..style = PaintingStyle.fill;
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy)
            ..arcTo(Rect.fromCircle(center: center, radius: radius), segmentAngle, segmentSize, false)
            ..close(),
          paint,
        );
      }
    }

    // Bright ray
    final rayRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawPath(Path()..addArc(rayRect, sweepAngle - 0.1, 0.2), Paint()
      ..color = Colors.limeAccent.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    // Targets (unchanged)
    final targetPaint = Paint();
    for (final target in targets) {
      final normAngle = (target.angle * math.pi / 180) % (2 * math.pi);
      final pos = Offset(center.dx + radius * target.distance * math.cos(normAngle), center.dy + radius * target.distance * math.sin(normAngle));
      final diff = (normAngle - sweepAngle).abs() % (2 * math.pi);
      final intensity = (1 - math.min(diff, 2 * math.pi - diff) / (math.pi / 6)).clamp(0.0, 1.0);
      targetPaint.color = target.color.withOpacity(0.8 * intensity);
      canvas.drawCircle(pos, 4 + intensity * 3, targetPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RadarPainter old) => old.sweepAngle != sweepAngle || old.targets != targets;
}
