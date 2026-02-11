import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/games/tower_stack/bloc/tower_stack_bloc.dart';
import 'package:green_object/games/tower_stack/bloc/tower_stack_event.dart';
import 'package:green_object/games/tower_stack/bloc/tower_stack_state.dart';
import 'package:flutter/scheduler.dart';
import 'package:green_object/ui/widgets/ad_rectangle.dart';
import 'package:green_object/utils/ad_manager.dart';

class TowerStackScreen extends StatefulWidget {
  static Widget route() {
    return BlocProvider(
      create: (context) => TowerStackBloc()..add(TowerStackStarted()),
      child: const TowerStackScreen(),
    );
  }

  const TowerStackScreen({super.key});

  @override
  State<TowerStackScreen> createState() => _TowerStackScreenState();
}

class _TowerStackScreenState extends State<TowerStackScreen>
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

    context.read<TowerStackBloc>().add(TowerStackTicked(deltaTime));
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      context.read<TowerStackBloc>().setScreenSize(size.width, size.height);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF222222),
      body: BlocConsumer<TowerStackBloc, TowerStackState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == TowerStackStatus.playing && !_ticker.isActive) {
            _lastTickTime = 0;
            _ticker.start();
          } else if (state.status == TowerStackStatus.gameOver &&
              _ticker.isActive) {
            _ticker.stop();
            AdManager.instance.onGameOver();
          }
        },
        builder: (context, state) {
          return GestureDetector(
            onTap: () {
              context.read<TowerStackBloc>().add(TowerStackTapped());
            },
            child: Stack(
              children: [
                // Game Area
                SizedBox.expand(
                  child: CustomPaint(painter: TowerStackPainter(state)),
                ),

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
                          color: Colors.cyanAccent,
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

                if (state.status == TowerStackStatus.gameOver)
                  _buildGameOver(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameOver(BuildContext context, TowerStackState state) {
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
                      color: Colors.cyanAccent,
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
                    onPressed: () => context.read<TowerStackBloc>().add(
                      TowerStackRestarted(),
                    ),
                    child: const Text("RETRY"),
                  ),
                  BlocBuilder<TowerStackBloc, TowerStackState>(
                    buildWhen: (previous, current) =>
                        previous.reviveUsed != current.reviveUsed,
                    builder: (context, state) {
                      if (state.reviveUsed) return const SizedBox.shrink();
                      return Column(
                        children: [
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () async {
                              final rewarded = await AdManager.instance
                                  .showRewarded(
                                    onRewardEarned: () {
                                      context.read<TowerStackBloc>().add(
                                        TowerStackRevived(),
                                      );
                                    },
                                  );
                              if (!rewarded && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Ad not ready. Try again soon.",
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: const Text("WATCH AD TO CONTINUE"),
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
    );
  }
}

class TowerStackPainter extends CustomPainter {
  final TowerStackState state;

  TowerStackPainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    // Camera Logic:
    // We want to keep the top of the stack visible.
    // Let's say we show 10 blocks height context.
    // Camera Y follows the top of the stack.

    final double blockHeight = state.blockHeight;
    final int score = state.score;

    // Virtual Y of the current moving block is (score + 1) * blockHeight
    // Stack top Y is score * blockHeight

    // We want "Stack Top" to be around 1/3 from the bottom? No, stacks go UP.
    // Screen BottomY = 0 logic Y?
    // Let's map Logic Y to Screen Y.
    // Screen Y = Size.height - LogicY - Padding.

    // Camera Offset
    // If score > 5, we shift everything down by (score - 5) * blockHeight
    double cameraYOffset = 0;
    if (score > 5) {
      cameraYOffset = (score - 5) * blockHeight;
    }

    // Draw Stack
    for (var block in state.stack) {
      _drawBlock(
        canvas,
        size,
        block.x,
        block.y * blockHeight,
        block.width,
        blockHeight,
        block.color,
        cameraYOffset,
      );
    }

    // Draw Moving Block
    // Logic Y = (score + 1) * blockHeight? Or we manually track it.
    // In Bloc, we only updated X. Y is implicit level = stack.length (if 0-based index is base).
    // Base is level 0.
    // New block is level score + 1?
    // Wait, base block is in stack. count=1. score=0.
    // Next block will be placed at y=1.
    // So current moving block logic Y = state.stack.length * blockHeight.

    double movingBlockY = state.stack.length * blockHeight;
    _drawBlock(
      canvas,
      size,
      state.currentBlockX,
      movingBlockY,
      state.currentBlockWidth,
      blockHeight,
      Colors.white,
      cameraYOffset,
    );
  }

  void _drawBlock(
    Canvas canvas,
    Size size,
    double x,
    double y,
    double w,
    double h,
    Color c,
    double offset,
  ) {
    // Screen Y calculation
    // Logic Y=0 is at bottom.
    // Screen Y = size.height - 100 - y + offset.
    // Actually, if we shift down, we subtraction offset?
    // If camera moves UP, objects move DOWN.
    // So Screen Y = (size.height - 100) - (y - offset).

    final screenY = (size.height - 100) - (y - offset);

    // If off screen, don't draw?
    if (screenY < -h || screenY > size.height) return;

    final rect = Rect.fromLTWH(x, screenY, w, h);
    final paint = Paint()..color = c;
    final border = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, border);
  }

  @override
  bool shouldRepaint(covariant TowerStackPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
