import 'package:flutter/material.dart';
import 'dart:math';

import 'package:moshaf/controllers/tasbeeh/tasbeeh_cubit.dart';



class TasbeehAnimation extends StatefulWidget {
  const TasbeehAnimation({super.key});

  @override
  State<TasbeehAnimation> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // stored bead t positions (can be <0 or >1 during animation)
  final List<double> _beads = [];

  // animation snapshot lists used while animating
  List<double> _startTs = [];
  List<double> _targetTs = [];

  static const double step = 0.12; // basic per-tap shift for most beads
  static const double eps = 1e-6;

  @override
  void initState() {
    super.initState();
    // initial layout: 5 left cluster, 2 right cluster (example positions)
    _beads.addAll([
      0.06, 0.20, 0.35, 0.50, 0.65, // left cluster (5)
    ]);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // commit final positions after animation finishes
        _commitAnimation();
      }
    });
  }

  bool get _isAnimating => _controller.isAnimating;

  /// Find the largest gap between sorted t positions (considering wrap)
  /// Returns index i where gap is between beads[i] and beads[(i+1)%n]
  int _largestGapIndex(List<double> sorted) {
    if (sorted.isEmpty) return 0;
    double bestGap = -1.0;
    int bestIndex = 0;
    for (int i = 0; i < sorted.length; i++) {
      final next = (i + 1) % sorted.length;
      double gap;
      if (next == 0) {
        // wrap gap: (sorted[0] + 1) - sorted[last]
        gap = (sorted[0] + 1.0) - sorted[i];
      } else {
        gap = sorted[next] - sorted[i];
      }
      if (gap > bestGap) {
        bestGap = gap;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  /// Called when user taps. Prepares start/target snapshots then animates.
  Future<void> _onTap() async {
    if (_isAnimating) return;

    // snapshot current positions as startTs
    _startTs = List<double>.from(_beads);

    if (_startTs.isEmpty) return;

    // Sort indices by t to find clusters and largest gap
    final indices = List<int>.generate(_startTs.length, (i) => i);
    indices.sort((a, b) => _startTs[a].compareTo(_startTs[b]));
    final sorted = indices.map((i) => _startTs[i]).toList();

    final gapIndexInSorted = _largestGapIndex(sorted);
    // The bead before the gap is at sorted[gapIndexInSorted] with original index indices[gapIndexInSorted]
    final leftMoverSortedIndex = gapIndexInSorted;
    final rightExitSortedIndex = (gapIndexInSorted + 1) % sorted.length;

    final leftMoverIndex = indices[leftMoverSortedIndex];
    final rightExitIndex = indices[rightExitSortedIndex];

    // compute values
    final leftStartT = _startTs[leftMoverIndex];
    final rightStartT = _startTs[rightExitIndex];

    // rightExit target = rightStartT + step (will exceed 1.0 => exit)
    final rightExitT = rightStartT + step;

    // left bead should travel to occupy the place of rightExitT (not wrapped)
    double leftTravel = rightExitT - leftStartT;
    if (leftTravel <= 0) leftTravel += 1.0; // ensure positive travel across wrap if necessary

    // Prepare targetTs: new bead will be added on left (minT - step) before animation,
    // then we compute targets:
    _targetTs = List<double>.from(_startTs);

    // First add new bead starting left of minT (so it will slide in)
    final minT = _startTs.reduce((a, b) => a < b ? a : b);
    // Add the new bead to the snapshots (so indices align with _beads list used for animation)
    _startTs.add(minT - step);
    _targetTs.add(minT - step); // placeholder; will be overwritten below for this new bead

    // Prepare targets: default shift by +step
    for (int i = 0; i < _targetTs.length; i++) {
      _targetTs[i] = _startTs[i] + step;
    }

    // Special-case assignments:
    // rightExit bead should go to rightExitT (exit)
    _targetTs[rightExitIndex] = rightExitT;

    // leftMover should go all the way to rightExitT (i.e., leftStart + leftTravel)
    _targetTs[leftMoverIndex] = leftStartT + leftTravel;

    // the newly added bead should end up joining left cluster: default behaviour already sets it to minT

    // Start animation (the painter will compute interpolated transientTs using these snapshots)
    _controller.forward(from: 0.0);
    TasbeehCubit.get(context).increment();
    setState(() {});
  }

  /// After animation, remove exiting bead(s), normalize positions and refresh.
  void _commitAnimation() {
    // commit targets into _beads
    _beads.clear();
    _beads.addAll(_targetTs);

    // remove beads that went beyond the right (t > 1.0 + small tolerance)
    _beads.removeWhere((t) => t > 1.0 + eps);

    // normalize remaining beads into [0,1)
    for (int i = 0; i < _beads.length; i++) {
      double t = _beads[i];
      t = (t % 1.0 + 1.0) % 1.0;
      _beads[i] = t;
    }

    // clear snapshots
    _startTs = [];
    _targetTs = [];

    // reset controller for next tap
    _controller.value = 0.0;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _progress() => Curves.easeOut.transform(_controller.value);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // compute transientTs for painting
          List<double> transientTs;
          if (_isAnimating && _startTs.isNotEmpty && _targetTs.isNotEmpty) {
            final p = _progress();
            transientTs = List<double>.generate(
              _startTs.length,
                  (i) => _startTs[i] + (_targetTs[i] - _startTs[i]) * p,
            );
          } else {
            transientTs = List<double>.from(_beads);
          }

          return CustomPaint(
            painter: _ClusterTasbeehPainter(transientTs: transientTs),
            child: Container(),
          );
        },
      ),
    );
  }
}

/// Painter that draws path + beads with glossy style and a slight rotation based on path tangent
class _ClusterTasbeehPainter extends CustomPainter {
  final List<double> transientTs; // t values during painting (can be <0 or >1 while animating)
  _ClusterTasbeehPainter({
    required this.transientTs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final centerY = size.height * 0.45;

    // --- path (sine curve)
    final path = Path();
    const waves = 1.0;
    final amplitude = size.height * 0.045;
    for (double x = 0; x <= width; x++) {
      final t = x / width;
      final y = centerY + sin(t * 2 * pi * waves - 0.28) * amplitude;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // draw thread
    final threadPaint = Paint()
      ..color = Colors.grey.shade800.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, threadPaint);

    final metric = path.computeMetrics().first;
    const beadDiameter = 30.0;
    final beadRadius = beadDiameter / 2;

    // sort beads by transient t so they are drawn left->right
    final indexed = List<int>.generate(transientTs.length, (i) => i);
    indexed.sort((a, b) => transientTs[a].compareTo(transientTs[b]));

    for (final idx in indexed) {
      final t = transientTs[idx];
      // skip beads far outside visible range for efficiency
      if (t < -0.5 || t > 1.5) continue;

      final sampleT = t.clamp(0.0, 1.0);
      final offsetAlong = metric.length * sampleT;
      final tangent = metric.getTangentForOffset(offsetAlong);
      if (tangent == null) continue;
      final pos = tangent.position;

      // small perpendicular offset so bead looks like sitting on thread
      final perp = Offset(-tangent.vector.dy, tangent.vector.dx);
      final perpNorm = perp / (perp.distance == 0 ? 1 : perp.distance);
      final sitOffset = perpNorm * 2.6;
      final beadCenter = pos + sitOffset;

      // Draw bead with rotation based on tangent direction
      canvas.save();
      canvas.translate(beadCenter.dx, beadCenter.dy);
      final angle = tangent.vector.direction;
      final rotation = angle * 0.18; // subtle rotation
      canvas.rotate(rotation);

      // draw shadow (screen-aligned): undo rotation
      canvas.save();
      canvas.rotate(-rotation);
      final shadowPaint = Paint()..color = Colors.black.withOpacity(0.18);
      canvas.drawCircle(const Offset(4, 6), beadRadius * 1.02, shadowPaint);
      canvas.restore();

      // --- GREEN RIM (matches your asset) ---
      final rimPaint = Paint()..color = const Color(0xFF0B6A3A);
      canvas.drawCircle(Offset.zero, beadRadius, rimPaint);

      // --- INNER GREEN GLOSSY GRADIENT ---
      // Center bright green, darker outer
      final innerRect = Rect.fromCircle(center: Offset.zero, radius: beadRadius * 0.86);
      final grad = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 0.9,
        colors: [
          const Color(0xFF22C55E), // bright center green
          const Color(0xFF0B6A3A), // darker outer green
        ],
        stops: const [0.10, 1.0],
      );
      final shaderPaint = Paint()..shader = grad.createShader(innerRect);
      canvas.drawCircle(Offset.zero, beadRadius * 0.86, shaderPaint);

      // specular highlight (top-left small oval) — slightly bluish-white like asset
      final highlight = Paint()..color = Colors.white.withOpacity(0.18);
      final highlightRect = Rect.fromCenter(
        center: Offset(-beadRadius * 0.18, -beadRadius * 0.28),
        width: beadRadius * 0.7,
        height: beadRadius * 0.44,
      );
      canvas.drawOval(highlightRect, highlight);

      // inner shadow ring for depth
      final innerShadow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = beadRadius * 0.12
        ..color = Colors.black.withOpacity(0.12);
      canvas.drawCircle(Offset.zero, beadRadius * 0.72, innerShadow);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ClusterTasbeehPainter old) {
    if (old.transientTs.length != transientTs.length) return true;
    for (int i = 0; i < transientTs.length; i++) {
      if ((old.transientTs[i] - transientTs[i]).abs() > 0.0001) return true;
    }
    return false;
  }
}
