import 'package:flutter/material.dart';
import 'package:green_object/services/analytics_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/bloc/game_bloc.dart';
import 'package:green_object/ui/widgets/game_canvas.dart';
import 'package:green_object/ui/widgets/game_over_overlay.dart';
import 'package:green_object/ui/widgets/score_hud.dart';
import 'package:flutter/scheduler.dart';
import 'package:green_object/utils/ad_manager.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  /// Static route helper that includes the BlocProvider
  static Widget route() {
    return BlocProvider(
      create: (context) => GameBloc()..add(GameStarted()),
      child: const GameScreen(),
    );
  }

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _lastTickTime = 0.0;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _startTime = DateTime.now();
    AnalyticsService.instance.logGameStart('Dodge');
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

    context.read<GameBloc>().add(GameTicked(deltaTime));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: BlocConsumer<GameBloc, GameState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == GameStatus.playing && !_ticker.isActive) {
            _lastTickTime = 0; // Reset tick time on restart
            _startTime = DateTime.now(); // Reset start time
            _ticker.start();
          } else if (state.status == GameStatus.gameOver && _ticker.isActive) {
            _ticker.stop();
            AdManager.instance.onGameOver();
            AnalyticsService.instance.logGameEnd(
              'Dodge',
              state.score.toInt(),
              DateTime.now().difference(_startTime).inSeconds,
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              GameCanvas(state: state),
              const ScoreHud(),
              // Back Button
              Positioned(
                top: 50,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              if (state.status == GameStatus.gameOver) const GameOverOverlay(),
            ],
          );
        },
      ),
    );
  }
}
