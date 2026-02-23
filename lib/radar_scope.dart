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
  late Animation<double> _trailAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.sweepDuration, vsync: this)..repeat();
    _sweepAnimation = Tween(begin: 0.0, end: 2 * math.pi).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _trailAnimation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.easeOut)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: widget.size, height: widget.size, child: AnimatedBuilder(
      animation: Listenable.merge([_sweepAnimation, _trailAnimation]),
      builder: (context, child) => CustomPaint(size: Size.square(widget.size), painter: RadarPainter(_sweepAnimation.value, _trailAnimation.value, widget.targets)),
    ));
  }
}

class RadarPainter extends CustomPainter {
  final double sweepAngle, trailDecay;
  final List<RadarTarget> targets;
  RadarPainter(this.sweepAngle, this.trailDecay, this.targets);

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

    // Fading trail
    final trailRect = Rect.fromCircle(center: center, radius: radius);
    final trailStops = [0.0, 0.05, 0.1, 0.3, 0.5, 0.7, 1.0];
    canvas.drawCircle(center, radius, Paint()
      ..shader = SweepGradient(
        colors: [Colors.transparent, Colors.transparent, Colors.transparent, Colors.green.withOpacity(0.05 * trailDecay), Colors.green.withOpacity(0.1 * trailDecay), Colors.green.withOpacity(0.2 * trailDecay), Colors.green.withOpacity(0.3 * trailDecay)],
        stops: trailStops,
        transform: GradientRotation(sweepAngle),
      ).createShader(trailRect));

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
  bool shouldRepaint(covariant RadarPainter old) => old.sweepAngle != sweepAngle || old.trailDecay != trailDecay || old.targets != targets;
}
