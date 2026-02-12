import 'package:flutter/material.dart';
import 'package:green_object/services/analytics_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/games/snake/bloc/snake_bloc.dart';
import 'package:green_object/games/snake/bloc/snake_event.dart';
import 'package:green_object/games/snake/bloc/snake_state.dart';
import 'package:flutter/scheduler.dart';
import 'package:green_object/ui/widgets/ad_rectangle.dart';
import 'package:green_object/utils/ad_manager.dart';

class SnakeScreen extends StatefulWidget {
  static Widget route() {
    return BlocProvider(
      create: (context) => SnakeBloc()..add(SnakeStarted()),
      child: const SnakeScreen(),
    );
  }

  const SnakeScreen({super.key});

  @override
  State<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends State<SnakeScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _lastTickTime = 0.0;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _startTime = DateTime.now();
    AnalyticsService.instance.logGameStart('Snake');
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

    context.read<SnakeBloc>().add(SnakeTicked(deltaTime));
  }

  void _changeDirection(int dx, int dy) {
    if (context.read<SnakeBloc>().state.status != SnakeStatus.playing) return;
    context.read<SnakeBloc>().add(SnakeDirectionChanged(dx, dy));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: BlocConsumer<SnakeBloc, SnakeState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == SnakeStatus.playing && !_ticker.isActive) {
            _lastTickTime = 0;
            _startTime = DateTime.now();
            _ticker.start();
          } else if (state.status == SnakeStatus.gameOver && _ticker.isActive) {
            _ticker.stop();
            AdManager.instance.onGameOver();
            AnalyticsService.instance.logGameEnd(
              'Snake',
              state.score,
              DateTime.now().difference(_startTime).inSeconds,
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Game Area
              Center(
                child: AspectRatio(
                  aspectRatio: SnakeBloc.gridColumns / SnakeBloc.gridRows,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: CustomPaint(painter: SnakePainter(state)),
                  ),
                ),
              ),

              // HUD
              Positioned(
                top: 50,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SCORE",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.54),
                        fontSize: 10,
                      ),
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
                    Text(
                      "HIGH SCORE",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.54),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      "${state.highScore}",
                      style: const TextStyle(
                        color: Colors.greenAccent,
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

              // Direction buttons
              Positioned(
                left: 0,
                right: 0,
                bottom: 60,
                child: _buildDirectionPad(),
              ),

              if (state.status == SnakeStatus.gameOver)
                _buildGameOver(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDirectionPad() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _directionButton(
          icon: Icons.keyboard_arrow_up_rounded,
          onTap: () => _changeDirection(0, -1),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _directionButton(
              icon: Icons.keyboard_arrow_left_rounded,
              onTap: () => _changeDirection(-1, 0),
            ),
            const SizedBox(width: 8),
            _directionButton(
              icon: Icons.keyboard_arrow_down_rounded,
              onTap: () => _changeDirection(0, 1),
            ),
            const SizedBox(width: 8),
            _directionButton(
              icon: Icons.keyboard_arrow_right_rounded,
              onTap: () => _changeDirection(1, 0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _directionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.greenAccent.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: Colors.greenAccent, size: 34),
        ),
      ),
    );
  }

  Widget _buildGameOver(BuildContext context, SnakeState state) {
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
                    "NEON SNACK", // Fixed title
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "GAME OVER",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 24,
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
                    onPressed: () =>
                        context.read<SnakeBloc>().add(SnakeRestarted()),
                    child: const Text("RETRY"),
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<SnakeBloc, SnakeState>(
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
                                      context.read<SnakeBloc>().add(
                                        SnakeRevived(),
                                      );
                                    },
                                    rewardType: 'revive',
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

class SnakePainter extends CustomPainter {
  final SnakeState state;

  SnakePainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / state.columns;
    final cellHeight = size.height / state.rows;

    // Grid (Optional, faint)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke;
    for (int i = 0; i <= state.columns; i++) {
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        gridPaint,
      );
    }
    for (int i = 0; i <= state.rows; i++) {
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        gridPaint,
      );
    }

    // Food
    final foodPaint = Paint()..color = Colors.redAccent;
    final foodRect = Rect.fromLTWH(
      state.food.x * cellWidth,
      state.food.y * cellHeight,
      cellWidth,
      cellHeight,
    );
    canvas.drawRect(foodRect.deflate(2), foodPaint);

    // Snake
    final snakePaint = Paint()..color = Colors.greenAccent;
    final headPaint = Paint()..color = Colors.green;

    for (int i = 0; i < state.snake.length; i++) {
      final point = state.snake[i];
      final rect = Rect.fromLTWH(
        point.x * cellWidth,
        point.y * cellHeight,
        cellWidth,
        cellHeight,
      );

      if (i == 0) {
        canvas.drawRect(rect.deflate(2), headPaint);
      } else {
        canvas.drawRect(rect.deflate(2), snakePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SnakePainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
