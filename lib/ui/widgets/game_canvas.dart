import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/bloc/game_bloc.dart';
import 'package:green_object/models/game_object.dart';

class GameCanvas extends StatelessWidget {
  final GameState state;

  const GameCanvas({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameBloc>().setScreenHeight(
        MediaQuery.of(context).size.height,
      );
    });

    return GestureDetector(
      onTapDown: (details) => _handleTap(context, details),
      child: Container(
        color: Colors.transparent,
        width: double.infinity,
        height: double.infinity,
        child: CustomPaint(painter: GamePainter(state)),
      ),
    );
  }

  void _handleTap(BuildContext context, TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;
    final laneWidth = screenWidth / 3;

    // Calculate Player Visual Center X
    final playerLane = state.playerLane;
    final playerXCenter = playerLane * laneWidth + (laneWidth / 2);

    int newLane = playerLane;

    // Relative Tap Logic
    if (tapX < playerXCenter) {
      // Tap Left of Player
      if (playerLane > 0) newLane = playerLane - 1;
    } else {
      // Tap Right of Player
      if (playerLane < 2) newLane = playerLane + 1;
    }

    // Optional: Visual Swipe feel could be added with animation but logic is simpler with direct set
    if (newLane != playerLane) {
      context.read<GameBloc>().add(PlayerMoved(newLane));
    }
  }
}

class GamePainter extends CustomPainter {
  final GameState state;

  GamePainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    final laneWidth = size.width / 3;

    // Draw Lanes
    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(laneWidth * i, 0),
        Offset(laneWidth * i, size.height),
        lanePaint,
      );
    }

    // Draw Player
    final playerX =
        state.playerLane * laneWidth + (laneWidth - GameBloc.playerSize) / 2;
    final playerY =
        size.height - GameBloc.playerSize - GameBloc.playerBottomPadding;

    final playerPaint = Paint()
      ..color = const Color(0xFF0f3460)
      ..style = PaintingStyle.fill;

    final playerGlow = Paint()
      ..color = const Color(0xFF0f3460).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    // Glow
    canvas.drawCircle(
      Offset(
        playerX + GameBloc.playerSize / 2,
        playerY + GameBloc.playerSize / 2,
      ),
      GameBloc.playerSize / 1.5,
      playerGlow,
    );

    // Body
    canvas.drawCircle(
      Offset(
        playerX + GameBloc.playerSize / 2,
        playerY + GameBloc.playerSize / 2,
      ),
      GameBloc.playerSize / 2,
      playerPaint,
    );

    // Core
    final playerCorePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(
        playerX + GameBloc.playerSize / 2,
        playerY + GameBloc.playerSize / 2,
      ),
      GameBloc.playerSize / 5,
      playerCorePaint,
    );

    // Draw Game Objects
    for (var obj in state.gameObjects) {
      final objX = obj.lane * laneWidth + (laneWidth - GameBloc.objectSize) / 2;

      if (obj.type == GameObjectType.obstacle) {
        _drawObstacle(canvas, objX, obj.y);
      } else {
        _drawCoin(canvas, objX, obj.y);
      }
    }
  }

  void _drawObstacle(Canvas canvas, double x, double y) {
    final paint = Paint()..color = const Color(0xFFe94560);
    final glow = Paint()
      ..color = const Color(0xFFe94560).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final rect = Rect.fromLTWH(x, y, GameBloc.objectSize, GameBloc.objectSize);

    canvas.drawRect(rect, glow);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      paint,
    );
  }

  void _drawCoin(Canvas canvas, double x, double y) {
    final center = Offset(
      x + GameBloc.objectSize / 2,
      y + GameBloc.objectSize / 2,
    );
    final paint = Paint()..color = Colors.amber;
    final glow = Paint()
      ..color = Colors.amber.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(center, GameBloc.objectSize / 2, glow);
    canvas.drawCircle(center, GameBloc.objectSize / 2.5, paint);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
