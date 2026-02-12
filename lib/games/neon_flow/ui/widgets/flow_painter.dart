import 'package:flutter/material.dart';
import 'package:green_object/games/neon_flow/bloc/neon_flow_state.dart';

class FlowPainter extends CustomPainter {
  final NeonFlowState state;

  FlowPainter(this.state);

  // Map IDs to Colors
  final List<Color> _colors = [
    Colors.grey, // 0 unused
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.yellowAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.tealAccent,
    Colors.indigoAccent,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final gridSize = state.size;
    final cellSize = size.width / gridSize;

    // Draw Grid Lines (Subtle)
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;

    for (int i = 0; i <= gridSize; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        gridPaint,
      );
    }

    // Draw Paths
    state.paths.forEach((id, points) {
      if (points.isEmpty) return;

      final color = _colors[id % _colors.length];

      final pathPaint = Paint()
        ..color = color
        ..strokeWidth = cellSize * 0.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..strokeWidth = cellSize * 0.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final path = Path();

      final start = points.first;
      path.moveTo(
        start.x * cellSize + cellSize / 2,
        start.y * cellSize + cellSize / 2,
      );

      for (int i = 1; i < points.length; i++) {
        final p = points[i];
        path.lineTo(
          p.x * cellSize + cellSize / 2,
          p.y * cellSize + cellSize / 2,
        );
      }

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, pathPaint);
    });

    // Draw Endpoints (Dots)
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final id = state.grid[r][c];
        if (id != 0) {
          final color = _colors[id % _colors.length];
          final center = Offset(
            c * cellSize + cellSize / 2,
            r * cellSize + cellSize / 2,
          );

          // Glow
          canvas.drawCircle(
            center,
            cellSize * 0.4,
            Paint()
              ..color = color.withValues(alpha: 0.4)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
          );

          // Dot
          canvas.drawCircle(center, cellSize * 0.3, Paint()..color = color);

          // Inner
          canvas.drawCircle(
            center,
            cellSize * 0.15,
            Paint()..color = Colors.white.withValues(alpha: 0.5),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant FlowPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
