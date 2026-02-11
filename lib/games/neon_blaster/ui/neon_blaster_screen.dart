import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/games/neon_blaster/bloc/neon_blaster_bloc.dart';
import 'package:green_object/games/neon_blaster/bloc/neon_blaster_event.dart';
import 'package:green_object/games/neon_blaster/bloc/neon_blaster_state.dart';
import 'package:green_object/ui/widgets/ad_rectangle.dart';
import 'package:green_object/utils/ad_manager.dart';

class NeonBlasterScreen extends StatefulWidget {
  static Widget route() {
    return BlocProvider(
      create: (_) => NeonBlasterBloc()..add(NeonBlasterStarted()),
      child: const NeonBlasterScreen(),
    );
  }

  const NeonBlasterScreen({super.key});

  @override
  State<NeonBlasterScreen> createState() => _NeonBlasterScreenState();
}

class _NeonBlasterScreenState extends State<NeonBlasterScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _lastTickTime = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final currentTime = elapsed.inMicroseconds / 1000000.0;
    if (_lastTickTime == 0) {
      _lastTickTime = currentTime;
      return;
    }
    final deltaTime = currentTime - _lastTickTime;
    _lastTickTime = currentTime;
    context.read<NeonBlasterBloc>().add(NeonBlasterTicked(deltaTime));
  }

  void _movePlayer(double globalX) {
    final width = MediaQuery.of(context).size.width;
    final x = (globalX / width).clamp(0.0, 1.0);
    context.read<NeonBlasterBloc>().add(NeonBlasterPlayerMoved(x));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B18),
      body: BlocConsumer<NeonBlasterBloc, NeonBlasterState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == NeonBlasterStatus.playing && !_ticker.isActive) {
            _lastTickTime = 0;
            _ticker.start();
          } else if (state.status == NeonBlasterStatus.gameOver &&
              _ticker.isActive) {
            _ticker.stop();
            AdManager.instance.onGameOver();
          }
        },
        builder: (context, state) {
          return GestureDetector(
            onHorizontalDragUpdate: (details) =>
                _movePlayer(details.globalPosition.dx),
            onTapDown: (details) => _movePlayer(details.globalPosition.dx),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _BlasterPainter(state)),
                ),

                Positioned(
                  top: 50,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SCORE ${state.score}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "LEVEL ${state.level}",
                        style: const TextStyle(
                          color: Colors.lightBlueAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "COMBO x${1 + (state.combo ~/ 5)}",
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: 50,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "HIGH",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "${state.highScore}",
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (state.hasMagnet)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt,
                                color: Colors.purpleAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "MAGNET",
                                style: TextStyle(
                                  color: Colors.purpleAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    BoxShadow(
                                      color: Colors.purple.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (state.hasSlowMotion)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "SLOW MO",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Positioned(
                  top: 45,
                  left: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Text(
                    "Drag anywhere to move. Auto-fire is ON.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ),

                if (state.status == NeonBlasterStatus.gameOver)
                  _buildGameOver(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameOver(BuildContext context, NeonBlasterState state) {
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "NEON BLASTER",
                    style: TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "GAME OVER",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Score: ${state.score}",
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                  ),
                  Text(
                    "High Score: ${state.highScore}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.read<NeonBlasterBloc>().add(
                      NeonBlasterRestarted(),
                    ),
                    child: const Text("RETRY"),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      const int rewardBonus = 100;
                      final rewarded = await AdManager.instance.showRewarded(
                        onRewardEarned: () {
                          context.read<NeonBlasterBloc>().add(
                            const NeonBlasterRestarted(bonusScore: rewardBonus),
                          );
                        },
                      );
                      if (!rewarded && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Ad not ready. Try again soon."),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text("WATCH AD +100"),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 330, child: const AdRectangle()),
        ],
      ),
    );
  }
}

class _BlasterPainter extends CustomPainter {
  final NeonBlasterState state;

  _BlasterPainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF030714), Color(0xFF0A1838)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (int i = 0; i < 120; i++) {
      final x = ((i * 97) % 1000) / 1000 * size.width;
      final y = ((i * 57) % 1000) / 1000 * size.height;
      canvas.drawCircle(Offset(x, y), i % 7 == 0 ? 1.3 : 0.8, starPaint);
    }

    final bulletPaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final b in state.bullets) {
      final x = b.x * size.width;
      final y = b.y * size.height;
      canvas.drawLine(Offset(x, y + 10), Offset(x, y - 10), bulletPaint);
    }

    final enemyPaint = Paint()
      ..color = Colors.pinkAccent
      ..style = PaintingStyle.fill;
    final enemyGlow = Paint()
      ..color = Colors.pinkAccent.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (final e in state.enemies) {
      final center = Offset(e.x * size.width, e.y * size.height);
      final radius = max(8.0, e.radius * size.width);
      canvas.drawCircle(center, radius * 1.5, enemyGlow);
      canvas.drawCircle(center, radius, enemyPaint);

      if (e.hp > 0) {
        textPainter.text = TextSpan(
          text: "${e.hp}",
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 1.0,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          center - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }

    final shipX = state.playerX * size.width;
    final shipY = NeonBlasterBloc.playerY * size.height;
    final shipPath = Path()
      ..moveTo(shipX, shipY - 18)
      ..lineTo(shipX - 16, shipY + 14)
      ..lineTo(shipX, shipY + 6)
      ..lineTo(shipX + 16, shipY + 14)
      ..close();

    final shipPaint = Paint()..color = Colors.greenAccent;
    final shipGlow = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(shipPath, shipGlow);
    canvas.drawPath(shipPath, shipPaint);
  }

  @override
  bool shouldRepaint(covariant _BlasterPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
