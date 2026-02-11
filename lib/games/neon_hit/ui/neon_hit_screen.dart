import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_object/games/neon_hit/bloc/neon_hit_bloc.dart';
import 'package:green_object/games/neon_hit/bloc/neon_hit_event.dart';
import 'package:green_object/games/neon_hit/bloc/neon_hit_state.dart';
import 'package:green_object/ui/widgets/ad_rectangle.dart';
import 'package:green_object/utils/ad_manager.dart';

class NeonHitScreen extends StatelessWidget {
  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => const NeonHitScreen());
  }

  const NeonHitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NeonHitBloc()..add(GameStarted()),
      child: const _NeonHitView(),
    );
  }
}

class _NeonHitView extends StatelessWidget {
  const _NeonHitView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<NeonHitBloc, NeonHitState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == GameStatus.gameOver) {
            AdManager.instance.onGameOver();
          }
        },
        builder: (context, state) {
          return GestureDetector(
            onTap: () => context.read<NeonHitBloc>().add(ThrowSpike()),
            child: Stack(
              children: [
                // Game Area
                CustomPaint(painter: _GamePainter(state), size: Size.infinite),

                // Score & Level
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        state.score.toString(),
                        style: GoogleFonts.pressStart2p(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 48,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "LEVEL ${state.level}",
                        style: GoogleFonts.pressStart2p(
                          color: Colors.yellowAccent,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
                          color: Colors.cyanAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Ammo Counter (Spikes Left)
                Positioned(
                  bottom: 40,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SPIKES: ${state.spikesLeft}",
                        style: GoogleFonts.pressStart2p(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          state.spikesLeft,
                          (index) => const Padding(
                            padding: EdgeInsets.only(right: 4.0, top: 8.0),
                            child: Icon(
                              Icons.change_history,
                              color: Colors.cyanAccent,
                              size: 16,
                            ),
                          ),
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
                                    context.read<NeonHitBloc>().add(
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
                                OutlinedButton(
                                  onPressed: () async {
                                    const int rewardBonus = 5;
                                    final rewarded = await AdManager.instance
                                        .showRewarded(
                                          onRewardEarned: () {
                                            context.read<NeonHitBloc>().add(
                                              const GameReset(
                                                bonusScore: rewardBonus,
                                              ),
                                            );
                                          },
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
                                  child: Text(
                                    "WATCH AD +5",
                                    style: GoogleFonts.pressStart2p(
                                      fontSize: 12,
                                    ),
                                  ),
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
  final NeonHitState state;

  _GamePainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final double targetRadius = 60.0;

    // Draw Target
    // We need to rotate the canvas for the target
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(state.targetRotation);

    final paintTarget = Paint()
      ..color = Colors.pinkAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    final paintTargetFill = Paint()
      ..color = Colors.pinkAccent.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, targetRadius, paintTarget);
    canvas.drawCircle(Offset.zero, targetRadius, paintTargetFill);

    // Draw Stuck Spikes
    // Stuck spikes are angles relative to target center.
    // They rotate WITH the target (because we rotated canvas).
    final paintSpike = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double spikeLength = 40.0;

    for (double angle in state.stuckSpikes) {
      // Angle 0 is right (0 rad).
      // We want spike sticking OUT.
      // Line from radius to radius + length.
      final p1 = Offset(cos(angle) * targetRadius, sin(angle) * targetRadius);
      final p2 = Offset(
        cos(angle) * (targetRadius + spikeLength),
        sin(angle) * (targetRadius + spikeLength),
      );
      canvas.drawLine(p1, p2, paintSpike);
    }

    canvas.restore(); // Restore to normal non-rotated canvas

    // Draw Flying Spikes
    // These move from bottom to center.
    // Progress 0.0 is bottom, 0.8 is hit.
    // Let's say spawn is at Y = size.height - 100.
    // Target is center.
    // Distance = (size.height - 100) - center.dy.
    final double startY = size.height - 100;
    final double targetY =
        center.dy + targetRadius; // Hit point is bottom of circle
    final double totalDist = startY - targetY;

    for (double progress in state.flyingSpikes) {
      // progress 0 -> y = startY
      // progress 0.8 -> y = targetY
      // normalized 0.0 to 0.8 maps to 0 to TotalDist
      // currentY = startY - (progress / 0.8) * totalDist

      double currentY = startY - (progress / 0.8) * totalDist;

      // Draw spike pointing UP
      canvas.drawLine(
        Offset(center.dx, currentY),
        Offset(center.dx, currentY + spikeLength),
        paintSpike,
      );
    }

    // Draw "Ready" Spike at bottom
    if (state.spikesLeft > 0) {
      canvas.drawLine(
        Offset(center.dx, startY),
        Offset(center.dx, startY + spikeLength),
        paintSpike..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
