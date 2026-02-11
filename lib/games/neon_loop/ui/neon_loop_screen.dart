import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_object/games/neon_loop/bloc/neon_loop_bloc.dart';
import 'package:green_object/games/neon_loop/bloc/neon_loop_event.dart';
import 'package:green_object/games/neon_loop/bloc/neon_loop_state.dart';
import 'package:green_object/ui/widgets/ad_rectangle.dart';
import 'package:green_object/utils/ad_manager.dart';

class NeonLoopScreen extends StatefulWidget {
  static Widget route() {
    return BlocProvider(
      create: (context) => NeonLoopBloc()..add(const NeonLoopStarted()),
      child: const NeonLoopScreen(),
    );
  }

  const NeonLoopScreen({super.key});

  @override
  State<NeonLoopScreen> createState() => _NeonLoopScreenState();
}

class _NeonLoopScreenState extends State<NeonLoopScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _lastTime = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final double currentTime = elapsed.inMicroseconds / 1000000.0;
    if (_lastTime > 0) {
      final double dt = currentTime - _lastTime;
      context.read<NeonLoopBloc>().add(NeonLoopTicked(dt));
    }
    _lastTime = currentTime;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0b0b1a),
      body: BlocConsumer<NeonLoopBloc, NeonLoopState>(
        listener: (context, state) {
          if (state.status == NeonLoopStatus.gameOver) {
            _ticker.stop();
            AdManager.instance.onGameOver();
          } else if (!_ticker.isActive) {
            _ticker.start();
            _lastTime = 0;
          }
        },
        builder: (context, state) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                context.read<NeonLoopBloc>().add(const NeonLoopTapped()),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Custom Paint for the loop
                Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(50.0),
                      child: CustomPaint(painter: _NeonLoopPainter(state)),
                    ),
                  ),
                ),

                // Score HUD
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "SCORE",
                                  style: GoogleFonts.pressStart2p(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  state.score.toString(),
                                  style: GoogleFonts.pressStart2p(
                                    color: Colors.white,
                                    fontSize: 24,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "HIGH",
                                  style: GoogleFonts.pressStart2p(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  state.highScore.toString(),
                                  style: GoogleFonts.pressStart2p(
                                    color: Colors.amberAccent,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Back Button
                Positioned(
                  top: 50,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.only(top: 60), // Space for score
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),

                // Tap Guide
                if (state.status == NeonLoopStatus.playing && state.score == 0)
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        "TAP WHEN BALL ENTERS TARGET!",
                        style: GoogleFonts.pressStart2p(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),

                // Game Over Overlay
                if (state.status == NeonLoopStatus.gameOver)
                  _buildGameOver(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameOver(BuildContext context, NeonLoopState state) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
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
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "SCORE: ${state.score}",
                    style: GoogleFonts.pressStart2p(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => context.read<NeonLoopBloc>().add(
                      const NeonLoopRestarted(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                    ),
                    child: Text(
                      "RETRY",
                      style: GoogleFonts.pressStart2p(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton(
                    onPressed: () async {
                      final rewarded = await AdManager.instance.showRewarded(
                        onRewardEarned: () {
                          context.read<NeonLoopBloc>().add(
                            const NeonLoopRestarted(bonusScore: 50),
                          );
                        },
                      );
                      if (!rewarded && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Ad not ready. Try again later."),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: Text(
                      "WATCH AD +50",
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 330, child: AdRectangle()),
        ],
      ),
    );
  }
}

class _NeonLoopPainter extends CustomPainter {
  final NeonLoopState state;
  _NeonLoopPainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Draw track
    final paintTrack = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, paintTrack);

    // Draw target zone
    final paintTarget = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Draw arc for target
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      state.targetAngle - (state.targetWidth / 2),
      state.targetWidth,
      false,
      paintTarget,
    );

    // Glow for target
    final paintTargetGlow = Paint()
      ..color = Colors.yellowAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      state.targetAngle - (state.targetWidth / 2),
      state.targetWidth,
      false,
      paintTargetGlow,
    );

    // Draw ball
    final ballPos = Offset(
      center.dx + radius * cos(state.ballAngle),
      center.dy + radius * sin(state.ballAngle),
    );

    final paintBall = Paint()..color = Colors.cyanAccent;
    canvas.drawCircle(ballPos, 12, paintBall);

    // Ball glow
    final paintBallGlow = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(ballPos, 18, paintBallGlow);
  }

  @override
  bool shouldRepaint(covariant _NeonLoopPainter oldDelegate) => true;
}
