import 'dart:math';
import 'package:flutter/material.dart';
import 'radar_scope.dart';  // Your radar_scope.dart here

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Dynamic Radar Demo',
    darkTheme: ThemeData.dark(),
    home: const RadarHome(),
  );
}

class RadarHome extends StatefulWidget {
  const RadarHome({super.key});

  @override State<RadarHome> createState() => _RadarHomeState();
}

class _RadarHomeState extends State<RadarHome> {
  final List<RadarTarget> _targets = [];
  final Random _rng = Random();

  void _addRandomTarget() {
    setState(() {
      _targets.add(RadarTarget(
        angle: _rng.nextDouble() * 360,
        distance: 0.2 + _rng.nextDouble() * 0.8,
        color: _rng.nextBool() ? Colors.yellow : (_rng.nextBool() ? Colors.red : Colors.cyan),
      ));
      if (_targets.length > 20) _targets.removeAt(0);
    });
  }

  void _clearTargets() {
    setState(() => _targets.clear());
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Radar: ${_targets.length} targets'),
      actions: [
        IconButton(icon: const Icon(Icons.clear), onPressed: _clearTargets),
      ],
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RadarScope(
              size: 320,
              sweepDuration: const Duration(seconds: 2),
              targets: _targets,
            ),
            const SizedBox(height: 24),
            Text('${_targets.length} active targets', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _addRandomTarget,
      child: const Icon(Icons.add_circle_outline),
      tooltip: 'Add random target',
    ),
  );
}
