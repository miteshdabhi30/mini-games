import 'package:flutter/material.dart';
import 'package:green_object/services/analytics_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/games/pattern_match/bloc/pattern_match_bloc.dart';
import 'package:green_object/games/pattern_match/bloc/pattern_match_event.dart';
import 'package:green_object/games/pattern_match/bloc/pattern_match_state.dart';
import 'package:green_object/ui/widgets/ad_rectangle.dart';
import 'package:green_object/utils/ad_manager.dart';

class PatternMatchScreen extends StatefulWidget {
  static Widget route() {
    return BlocProvider(
      create: (context) => PatternMatchBloc()..add(const PatternMatchStarted()),
      child: const PatternMatchScreen(),
    );
  }

  const PatternMatchScreen({super.key});

  @override
  State<PatternMatchScreen> createState() => _PatternMatchScreenState();
}

class _PatternMatchScreenState extends State<PatternMatchScreen> {
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    AnalyticsService.instance.logGameStart('Pattern Match');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: BlocConsumer<PatternMatchBloc, PatternMatchState>(
        listener: (context, state) {
          if (state.status == PatternMatchStatus.gameOver) {
            AdManager.instance.onGameOver();
            AnalyticsService.instance.logGameEnd(
              'Pattern Match',
              state.score,
              DateTime.now().difference(_startTime).inSeconds,
            );
          } else if (state.status == PatternMatchStatus.idle &&
              state.score == 0) {
            // Assuming idle with score 0 means restart/start
            _startTime = DateTime.now();
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Main Game Area
              SafeArea(
                child: Column(
                  children: [
                    // Header with score and back button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
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
                                  color: Colors.amber,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Round indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Text(
                            "ROUND",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.54),
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            "${state.currentRound}",
                            style: const TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status text
                    Text(
                      _getStatusText(state.status),
                      style: TextStyle(
                        color: _getStatusColor(state.status),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    // Game buttons grid
                    Center(
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            return _PatternButton(
                              index: index,
                              isHighlighted: state.highlightedButton == index,
                              isEnabled:
                                  state.status == PatternMatchStatus.playerTurn,
                              onTap: () {
                                context.read<PatternMatchBloc>().add(
                                  PatternMatchButtonTapped(index),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    const Spacer(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Game Over Overlay
              if (state.status == PatternMatchStatus.gameOver)
                _buildGameOver(context, state),
            ],
          );
        },
      ),
    );
  }

  String _getStatusText(PatternMatchStatus status) {
    switch (status) {
      case PatternMatchStatus.idle:
        return "Get Ready...";
      case PatternMatchStatus.showingPattern:
        return "Watch the Pattern!";
      case PatternMatchStatus.playerTurn:
        return "Your Turn!";
      case PatternMatchStatus.gameOver:
        return "";
    }
  }

  Color _getStatusColor(PatternMatchStatus status) {
    switch (status) {
      case PatternMatchStatus.idle:
        return Colors.white.withValues(alpha: 0.7);
      case PatternMatchStatus.showingPattern:
        return Colors.cyanAccent;
      case PatternMatchStatus.playerTurn:
        return Colors.greenAccent;
      case PatternMatchStatus.gameOver:
        return Colors.red;
    }
  }

  Widget _buildGameOver(BuildContext context, PatternMatchState state) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
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
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Round: ${state.currentRound}",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Score: ${state.score}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "High Score: ${state.highScore}",
                    style: const TextStyle(color: Colors.amber, fontSize: 18),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => context.read<PatternMatchBloc>().add(
                      const PatternMatchRestarted(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      "RETRY",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<PatternMatchBloc, PatternMatchState>(
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
                                      context.read<PatternMatchBloc>().add(
                                        const PatternMatchRevived(),
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
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.54),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 16,
                              ),
                            ),
                            child: const Text(
                              "WATCH AD TO CONTINUE",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
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
          const SizedBox(height: 330, child: AdRectangle()),
        ],
      ),
    );
  }
}

class _PatternButton extends StatelessWidget {
  final int index;
  final bool isHighlighted;
  final bool isEnabled;
  final VoidCallback onTap;

  const _PatternButton({
    required this.index,
    required this.isHighlighted,
    required this.isEnabled,
    required this.onTap,
  });

  Color get _baseColor {
    switch (index) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isHighlighted ? _baseColor : _baseColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlighted
                ? _baseColor.withValues(alpha: 0.8)
                : _baseColor.withValues(alpha: 0.4),
            width: 4,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: _baseColor.withValues(alpha: 0.6),
                    blurRadius: 25,
                    spreadRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
      ),
    );
  }
}
