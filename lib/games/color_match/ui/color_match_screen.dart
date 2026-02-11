import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/games/color_match/bloc/color_match_bloc.dart';
import 'package:green_object/games/color_match/bloc/color_match_event.dart';
import 'package:green_object/games/color_match/bloc/color_match_state.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;
import 'package:green_object/ui/widgets/ad_rectangle.dart';
import 'package:green_object/utils/ad_manager.dart';

class ColorMatchScreen extends StatefulWidget {
  static Widget route() {
    return BlocProvider(
      create: (context) => ColorMatchBloc()..add(ColorMatchStarted()),
      child: const ColorMatchScreen(),
    );
  }

  const ColorMatchScreen({super.key});

  @override
  State<ColorMatchScreen> createState() => _ColorMatchScreenState();
}

class _ColorMatchScreenState extends State<ColorMatchScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _lastTickTime = 0.0;

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

    final double currentTime = elapsed.inMicroseconds / 1000000.0;
    if (_lastTickTime == 0.0) {
      _lastTickTime = currentTime;
      return;
    }

    final double deltaTime = currentTime - _lastTickTime;
    _lastTickTime = currentTime;

    context.read<ColorMatchBloc>().add(ColorMatchTicked(deltaTime));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF222222),
      body: BlocConsumer<ColorMatchBloc, ColorMatchState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == ColorMatchStatus.playing && !_ticker.isActive) {
            _lastTickTime = 0;
            _ticker.start();
          } else if (state.status == ColorMatchStatus.gameOver &&
              _ticker.isActive) {
            _ticker.stop();
            AdManager.instance.onGameOver();
          }
        },
        builder: (context, state) {
          return GestureDetector(
            onTap: () {
              context.read<ColorMatchBloc>().add(ColorMatchRotated());
            },
            child: Stack(
              children: [
                // Game Area
                _buildGameArea(context, state),

                // HUD
                Positioned(
                  top: 50,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SCORE",
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                      Text(
                        "${state.score}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "HIGH SCORE",
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                      Text(
                        "${state.highScore}",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Back Button
                Positioned(
                  top: 50,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                if (state.status == ColorMatchStatus.gameOver)
                  _buildGameOver(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameArea(BuildContext context, ColorMatchState state) {
    return SizedBox.expand(
      child: CustomPaint(painter: ColorMatchPainter(state)),
    );
  }

  Widget _buildGameOver(BuildContext context, ColorMatchState state) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "GAME OVER",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Score: ${state.score}",
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  Text(
                    "High Score: ${state.highScore}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.read<ColorMatchBloc>().add(
                      ColorMatchRestarted(),
                    ),
                    child: const Text("RETRY"),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      const int rewardBonus = 50;
                      final rewarded = await AdManager.instance.showRewarded(
                        onRewardEarned: () {
                          context.read<ColorMatchBloc>().add(
                            const ColorMatchRestarted(bonusScore: rewardBonus),
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
                    child: const Text("WATCH AD +50"),
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

class ColorMatchPainter extends CustomPainter {
  final ColorMatchState state;

  ColorMatchPainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    // Wheel Logic:
    // Colors: Red, Blue, Green, Yellow.
    // Index 0: facing UP?
    // We draw the wheel rotated by -90 * rotationIndex?
    // Or we draw segments fixed relative to rotation.

    // Let's say we draw 4 segments.
    // Top segment color is: colors[state.rotationIndex].
    // Right segment: colors[(index+1)%4]
    // Bottom: ...
    // Left: ...
    // Wait, if Tap rotates, does it rotate the *wheel* visually? Yes.
    // If we want [Red] to be at Top when index=0.
    // And when we tap to index=1, we want [Blue] to be at Top.
    // This means visually the wheel rotates so Blue (which was right?) moves to Top.
    // This implies Counter-Clockwise rotation of the wheel.

    // Config: [Red, Blue, Green, Yellow]
    // 0: Red is Top.
    // 1: Blue is Top.

    final double wheelRadius = 80.0;
    final double wheelY = size.height - 150.0;
    final center = Offset(centerX, wheelY);

    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.amber,
    ];

    // We visualize: Top Segment is colors[state.rotationIndex].
    // Right Segment is colors[(state.rotationIndex + 1) % 4]?
    // Let's verify:
    // If index=0: Top=Red.
    // If index=1: Top=Blue.
    // This means Blue must have been to the Right (90deg CW) of Red?
    // If so, rotating 90deg CCW brings Right to Top.
    // Yes.

    // So we draw segments:
    // Segment 0 (Top, -45 to 45 deg? No, -135 to -45 is Top? 270 to 360?)
    // Standard drawArc starts at 0 (Right).
    // Segment order in list: 0, 1, 2, 3.
    // We want Color[index] to be at -90 deg (Top).
    // So we rotate the whole canvas so that segment[index] is at -90.
    // Or we just draw segments based on current top index.

    // Simplest: Draw 4 arcs using the colors list, shifted by `state.rotationIndex`.
    // Top Arc: colors[state.rotationIndex]
    // Right Arc: colors[(state.rotationIndex + 1)%4]
    // Bottom Arc: colors[(state.rotationIndex + 2)%4]
    // Left Arc: colors[(state.rotationIndex + 3)%4]

    final paint = Paint()..style = PaintingStyle.fill;

    // Top (-135 to -45 deg)
    paint.color = colors[state.rotationIndex];
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: wheelRadius),
      -math.pi * 3 / 4,
      math.pi / 2,
      true,
      paint,
    );

    // Right (-45 to 45 deg)
    paint.color = colors[(state.rotationIndex + 1) % 4];
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: wheelRadius),
      -math.pi / 4,
      math.pi / 2,
      true,
      paint,
    );

    // Bottom (45 to 135 deg)
    paint.color = colors[(state.rotationIndex + 2) % 4];
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: wheelRadius),
      math.pi / 4,
      math.pi / 2,
      true,
      paint,
    );

    // Left (135 to 225 deg)
    paint.color = colors[(state.rotationIndex + 3) % 4];
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: wheelRadius),
      math.pi * 3 / 4,
      math.pi / 2,
      true,
      paint,
    );

    // Draw Falling Balls
    for (var ball in state.balls) {
      paint.color = ball.uiColor;
      canvas.drawCircle(Offset(centerX, ball.y), 15.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ColorMatchPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
