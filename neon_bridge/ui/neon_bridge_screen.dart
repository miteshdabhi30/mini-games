import 'dart:math';
import 'package:flutter/material.dart';
import 'package:green_object/services/analytics_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_object/games/neon_bridge/bloc/neon_bridge_bloc.dart';
import 'package:green_object/games/neon_bridge/bloc/neon_bridge_event.dart';
import 'package:green_object/games/neon_bridge/bloc/neon_bridge_state.dart';
import 'package:green_object/ui/widgets/ad_rectangle.dart';
import 'package:green_object/utils/ad_manager.dart';

class NeonBridgeScreen extends StatelessWidget {
  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => const NeonBridgeScreen());
  }

  const NeonBridgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NeonBridgeBloc()..add(GameStarted()),
      child: const _NeonBridgeView(),
    );
  }
}

class _NeonBridgeView extends StatefulWidget {
  const _NeonBridgeView();

  @override
  State<_NeonBridgeView> createState() => _NeonBridgeViewState();
}

class _NeonBridgeViewState extends State<_NeonBridgeView>
    with SingleTickerProviderStateMixin {
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    AnalyticsService.instance.logGameStart('Neon Bridge');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<NeonBridgeBloc, NeonBridgeState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == GameStatus.gameOver) {
            AdManager.instance.onGameOver();
            AnalyticsService.instance.logGameEnd(
              'Neon Bridge',
              state.score,
              DateTime.now().difference(_startTime).inSeconds,
            );
          } else if (state.status == GameStatus.waiting) {
            _startTime = DateTime.now();
          }
        },
        builder: (context, state) {
          // Determine Background Colors based on Score for subtle gradient
          List<Color> gradientColors = [Colors.black, const Color(0xFF050510)];
          if (state.score >= 20) {
            gradientColors = [const Color(0xFF100010), const Color(0xFF200000)];
          } else if (state.score >= 10) {
            gradientColors = [const Color(0xFF000010), const Color(0xFF100020)];
          }

          // Shake Calculation
          double offsetX = 0;
          double offsetY = 0;
          if (state.shakeOffset > 0) {
            final random = Random();
            offsetX = (random.nextDouble() - 0.5) * state.shakeOffset;
            offsetY = (random.nextDouble() - 0.5) * state.shakeOffset;
          }

          return GestureDetector(
            onTapDown: (_) => context.read<NeonBridgeBloc>().add(StartGrow()),
            onTapUp: (_) => context.read<NeonBridgeBloc>().add(StopGrow()),
            child: Stack(
              children: [
                // Dynamic Background Container
                AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: gradientColors,
                    ),
                  ),
                ),

                // Game World with Shake
                Transform.translate(
                  offset: Offset(offsetX, offsetY),
                  child: CustomPaint(
                    painter: _GamePainter(state),
                    size: Size.infinite,
                  ),
                ),

                // Score HUD
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      state.score.toString(),
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 48,
                        shadows: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // High Score
                Positioned(
                  top: 60,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "HIGH",
                        style: GoogleFonts.pressStart2p(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.highScore.toString(),
                        style: GoogleFonts.pressStart2p(
                          color: Colors.pinkAccent,
                          fontSize: 12,
                          shadows: [
                            const Shadow(blurRadius: 10, color: Colors.pink),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Back Button
                Positioned(
                  top: 50,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white70,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                // Perfect Combo Text
                if (state.comboCount > 0)
                  Positioned(
                    top: 180,
                    left: 0,
                    right: 0,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  "PERFECT!",
                                  style: GoogleFonts.pressStart2p(
                                    color: Colors.yellowAccent,
                                    fontSize: 20,
                                    shadows: [
                                      const Shadow(
                                        blurRadius: 15,
                                        color: Colors.orange,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "x${state.comboCount}",
                                  style: GoogleFonts.pressStart2p(
                                    color: Colors.orangeAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Game Over Overlay
                if (state.status == GameStatus.gameOver)
                  Container(
                    color: Colors.black87,
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "GAME OVER",
                                  style: GoogleFonts.pressStart2p(
                                    color: Colors.redAccent,
                                    fontSize: 36,
                                    shadows: [
                                      const Shadow(
                                        blurRadius: 20,
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "SCORE: ${state.score}",
                                  style: GoogleFonts.pressStart2p(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "BEST: ${state.highScore}",
                                  style: GoogleFonts.pressStart2p(
                                    color: Colors.purpleAccent,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<NeonBridgeBloc>().add(
                                      GameReset(),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        0,
                                      ), // Pixel style
                                    ),
                                  ),
                                  child: Text(
                                    "RETRY",
                                    style: GoogleFonts.pressStart2p(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                BlocBuilder<NeonBridgeBloc, NeonBridgeState>(
                                  buildWhen: (previous, current) =>
                                      previous.reviveUsed != current.reviveUsed,
                                  builder: (context, state) {
                                    if (state.reviveUsed) {
                                      return const SizedBox.shrink();
                                    }
                                    return OutlinedButton(
                                      onPressed: () async {
                                        final rewarded = await AdManager
                                            .instance
                                            .showRewarded(
                                              onRewardEarned: () {
                                                context
                                                    .read<NeonBridgeBloc>()
                                                    .add(GameRevived());
                                              },
                                              rewardType: 'revive',
                                            );
                                        if (!rewarded && context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Ad not ready. Try again soon.",
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.white54,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                      ),
                                      child: Text(
                                        "WATCH AD TO CONTINUE",
                                        style: GoogleFonts.pressStart2p(
                                          fontSize: 10,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 330, child: const AdRectangle()),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GamePainter extends CustomPainter {
  final NeonBridgeState state;

  _GamePainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * 0.65;

    // Draw Background Grid (Perspective)
    _drawGrid(canvas, size, centerY);

    final paintPlatform = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final paintPlatformGlow = Paint()
      ..color = Colors.purpleAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5);

    final paintPlatformCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw Red Dot (Perfect Zone) on Target Platform (index 1)
    final paintRedDot = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

    for (int i = 0; i < state.platforms.length; i++) {
      final platform = state.platforms[i];
      final rect = Rect.fromLTWH(
        platform.x,
        centerY,
        platform.width,
        size.height - centerY,
      );

      // Platform Body
      canvas.drawRect(rect, paintPlatform);

      // Neon Top
      // Multi-pass for glow
      canvas.drawLine(rect.topLeft, rect.topRight, paintPlatformGlow);
      canvas.drawLine(rect.topLeft, rect.topRight, paintPlatformCore);

      // If it's the target platform (index 1), draw the red dot in the center
      if (i == 1) {
        final centerX = platform.x + (platform.width / 2);
        canvas.drawCircle(Offset(centerX, centerY), 3, paintRedDot);
      }
    }

    // Draw Bridge
    if (state.platforms.isNotEmpty) {
      final startX = state.platforms[0].x + state.platforms[0].width;
      final startY = centerY;

      canvas.save();
      canvas.translate(startX, startY);
      canvas.rotate(state.bridgeAngle * 3.14159 / 180);

      // Bridge Glow
      final paintBridgeGlow = Paint()
        ..color = Colors.cyanAccent.withOpacity(0.6)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final paintBridgeCore = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final endPoint = Offset(0, -state.bridgeHeight);

      canvas.drawLine(Offset.zero, endPoint, paintBridgeGlow);
      canvas.drawLine(Offset.zero, endPoint, paintBridgeCore);

      canvas.restore();
    }

    // Draw Player
    _drawPlayer(canvas, centerY);

    // Draw Particles
    for (final p in state.particles) {
      final paintP = Paint()
        ..color = p.color.withOpacity(p.life)
        ..style = PaintingStyle.fill;

      // Simple circle particle
      canvas.drawCircle(Offset(p.x, centerY + p.y), p.size, paintP);
    }
  }

  void _drawGrid(Canvas canvas, Size size, double centerY) {
    // Simple cyberpunk grid below the platforms
    final paintGrid = Paint()
      ..color = Colors.purpleAccent.withOpacity(0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines with perspective
    for (double y = centerY; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    // Vertical lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, centerY), Offset(x, size.height), paintGrid);
    }
  }

  void _drawPlayer(Canvas canvas, double centerY) {
    final paintPlayerGlow = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final paintPlayer = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Player Y is tracked in state
    // Default yOffset is 0 (on top of platform which is at centerY)
    // Visual top of player should be centerY - 20 (height) + yOffset (gravity)
    // If yOffset increases (falling), player moves down.

    double yOffset = state.playerY;

    final rect = Rect.fromLTWH(
      state.playerX - 10,
      centerY + yOffset - 20,
      20,
      20,
    );

    canvas.drawRect(rect.inflate(4), paintPlayerGlow);
    canvas.drawRect(rect, paintPlayer);

    // Eye band
    final paintEye = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(state.playerX - 6, centerY + yOffset - 15, 16, 4),
      paintEye,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
