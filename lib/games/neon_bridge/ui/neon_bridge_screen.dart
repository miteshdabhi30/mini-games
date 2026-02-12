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

class _NeonBridgeViewState extends State<_NeonBridgeView> {
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
          return GestureDetector(
            onTapDown: (_) => context.read<NeonBridgeBloc>().add(StartGrow()),
            onTapUp: (_) => context.read<NeonBridgeBloc>().add(StopGrow()),
            child: Stack(
              children: [
                // Game Rendering
                CustomPaint(painter: _GamePainter(state), size: Size.infinite),

                // Score HUD
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      state.score.toString(),
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 48,
                      ),
                    ),
                  ),
                ),

                // High Score
                Positioned(
                  top: 50,
                  right: 16,
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
                      Text(
                        state.highScore.toString(),
                        style: GoogleFonts.pressStart2p(
                          color: Colors.pinkAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Back Button
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                // Game Over Overlay
                if (state.status == GameStatus.gameOver)
                  Container(
                    color: Colors.black54,
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
                                    color: Colors.red,
                                    fontSize: 32,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "High Score: ${state.highScore}",
                                  style: GoogleFonts.pressStart2p(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<NeonBridgeBloc>().add(
                                      GameReset(),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                  child: Text(
                                    "RETRY",
                                    style: GoogleFonts.pressStart2p(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                BlocBuilder<NeonBridgeBloc, NeonBridgeState>(
                                  buildWhen: (previous, current) =>
                                      previous.reviveUsed != current.reviveUsed,
                                  builder: (context, state) {
                                    if (state.reviveUsed) {
                                      return const SizedBox.shrink();
                                    }
                                    return Column(
                                      children: [
                                        const SizedBox(height: 12),
                                        OutlinedButton(
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
                                                  duration: Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: Text(
                                            "WATCH AD TO CONTINUE",
                                            style: GoogleFonts.pressStart2p(
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
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

    // Draw Platforms
    final paintPlatform = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final paintPlatformGlow = Paint()
      ..color = Colors.purpleAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5);

    for (var platform in state.platforms) {
      final rect = Rect.fromLTWH(
        platform.x,
        centerY,
        platform.width,
        size.height - centerY,
      );
      canvas.drawRect(rect, paintPlatform);
      canvas.drawLine(rect.topLeft, rect.topRight, paintPlatformGlow);
    }

    // Draw Bridge
    if (state.platforms.isNotEmpty) {
      final startX = state.platforms[0].x + state.platforms[0].width;
      final startY = centerY;

      canvas.save();
      canvas.translate(startX, startY);
      canvas.rotate(state.bridgeAngle * 3.14159 / 180);

      final paintBridge = Paint()
        ..color = Colors.cyanAccent
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset.zero, Offset(0, -state.bridgeHeight), paintBridge);

      canvas.restore();
    }

    // Draw Player
    final paintPlayer = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Simple square player
    canvas.drawRect(
      Rect.fromLTWH(state.playerX - 10, centerY - 20, 20, 20),
      paintPlayer,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
