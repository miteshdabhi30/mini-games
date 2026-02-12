import 'package:flutter/material.dart';
import 'package:green_object/services/analytics_service.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_object/games/math_rush/bloc/math_rush_bloc.dart';
import 'package:green_object/games/math_rush/bloc/math_rush_event.dart';
import 'package:green_object/games/math_rush/bloc/math_rush_state.dart';
import 'package:green_object/ui/widgets/ad_rectangle.dart';
import 'package:green_object/utils/ad_manager.dart';

class MathRushScreen extends StatefulWidget {
  const MathRushScreen({super.key});

  static Route route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => MathRushBloc()..add(const MathRushStarted()),
        child: const MathRushScreen(),
      ),
    );
  }

  @override
  State<MathRushScreen> createState() => _MathRushScreenState();
}

class _MathRushScreenState extends State<MathRushScreen>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  double _lastTickTime = 0.0;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _startTime = DateTime.now();
    AnalyticsService.instance.logGameStart('Math Rush');
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final double currentTime = elapsed.inMicroseconds / 1000000.0;
    if (_lastTickTime == 0.0) {
      _lastTickTime = currentTime;
      return;
    }

    final double deltaTime = currentTime - _lastTickTime;
    _lastTickTime = currentTime;

    context.read<MathRushBloc>().add(MathRushTicked(deltaTime));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MathRushBloc, MathRushState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == MathRushStatus.playing &&
            !(_ticker?.isActive ?? false)) {
          _lastTickTime = 0;
          _startTime = DateTime.now();
          _ticker?.start();
        } else if (state.status == MathRushStatus.gameOver &&
            (_ticker?.isActive ?? false)) {
          _ticker?.stop();
          AdManager.instance.onGameOver();
          AnalyticsService.instance.logGameEnd(
            'Math Rush',
            state.score,
            DateTime.now().difference(_startTime).inSeconds,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF1a1a2e),
          body: state.status == MathRushStatus.gameOver
              ? _buildGameOver(context, state)
              : _buildGame(context, state),
        );
      },
    );
  }

  Widget _buildGame(BuildContext context, MathRushState state) {
    if (state.currentQuestion == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final bool isCorrectFeedback = state.status == MathRushStatus.correct;
    final bool isWrongFeedback = state.status == MathRushStatus.wrong;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isCorrectFeedback
              ? [const Color(0xFF1a1a2e), Colors.green.shade900]
              : isWrongFeedback
              ? [const Color(0xFF1a1a2e), Colors.red.shade900]
              : [const Color(0xFF1a1a2e), const Color(0xFF16213e)],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Score and Level Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SCORE',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 10,
                              color: Colors.white60,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.score.toString().padLeft(5, '0'),
                            style: GoogleFonts.pressStart2p(
                              fontSize: 20,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'LEVEL',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 10,
                              color: Colors.white60,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.level.toString().padLeft(2, '0'),
                            style: GoogleFonts.pressStart2p(
                              fontSize: 20,
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Equation Display
                Expanded(
                  child: Center(
                    child: AnimatedScale(
                      scale: isCorrectFeedback ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 40,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213e),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.amberAccent.withValues(alpha: 0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amberAccent.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          state.currentQuestion!.displayEquation,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 32,
                            color: Colors.white,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),

                // Timer Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TIME',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 10,
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            state.timeRemaining.toStringAsFixed(1),
                            style: GoogleFonts.pressStart2p(
                              fontSize: 10,
                              color: state.timeRemaining < 2
                                  ? Colors.redAccent
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: state.timeRemaining / state.maxTime,
                          minHeight: 20,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            state.timeRemaining < 2
                                ? Colors.redAccent
                                : state.timeRemaining < 3
                                ? Colors.orangeAccent
                                : Colors.greenAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Answer Buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: state.currentQuestion!.options.map((option) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: _AnswerButton(
                            answer: option,
                            onTap: state.status == MathRushStatus.playing
                                ? () {
                                    context.read<MathRushBloc>().add(
                                      MathRushAnswered(option),
                                    );
                                  }
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'HIGH',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 10,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.highScore.toString().padLeft(5, '0'),
                    style: GoogleFonts.pressStart2p(
                      fontSize: 14,
                      color: Colors.amberAccent,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOver(BuildContext context, MathRushState state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF0f3460)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'GAME OVER',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 28,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213e),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.amberAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'FINAL SCORE',
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                state.score.toString(),
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 20,
                                  color: Colors.amberAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'HIGH SCORE',
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                state.highScore.toString(),
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 20,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Text(
                                'LEVEL REACHED',
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                state.level.toString(),
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        context.read<MathRushBloc>().add(
                          const MathRushRestarted(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: const Color(0xFF1a1a2e),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'PLAY AGAIN',
                        style: GoogleFonts.pressStart2p(fontSize: 14),
                      ),
                    ),
                    BlocBuilder<MathRushBloc, MathRushState>(
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
                                        context.read<MathRushBloc>().add(
                                          MathRushRevived(),
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
                                side: const BorderSide(color: Colors.white60),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                "WATCH AD TO CONTINUE",
                                style: GoogleFonts.pressStart2p(fontSize: 10),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'BACK TO HOME',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 10,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SizedBox(height: 330, child: const AdRectangle()),
          ],
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final int answer;
  final VoidCallback? onTap;

  const _AnswerButton({required this.answer, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: onTap != null
                ? [Colors.amberAccent, Colors.amber.shade700]
                : [Colors.grey.shade700, Colors.grey.shade800],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: onTap != null ? Colors.amber.shade300 : Colors.grey,
            width: 3,
          ),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: Colors.amberAccent.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            answer.toString(),
            style: GoogleFonts.pressStart2p(
              fontSize: 24,
              color: onTap != null ? const Color(0xFF1a1a2e) : Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
