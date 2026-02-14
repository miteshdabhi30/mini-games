import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_object/games/neon_flow/bloc/neon_flow_bloc.dart';
import 'package:green_object/games/neon_flow/bloc/neon_flow_event.dart';
import 'package:green_object/games/neon_flow/bloc/neon_flow_state.dart';
import 'package:green_object/games/neon_flow/ui/widgets/flow_painter.dart';
import 'package:green_object/services/analytics_service.dart';
import 'package:green_object/ui/widgets/ad_banner.dart';
import 'package:green_object/utils/ad_manager.dart';

class NeonFlowScreen extends StatefulWidget {
  const NeonFlowScreen({super.key});

  static Route route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => NeonFlowBloc()..add(const NeonFlowLevelStarted()),
        child: const NeonFlowScreen(),
      ),
    );
  }

  @override
  State<NeonFlowScreen> createState() => _NeonFlowScreenState();
}

class _NeonFlowScreenState extends State<NeonFlowScreen> {
  int _lastCompletedLevel = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logGameStart('Neon Flow');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: BlocConsumer<NeonFlowBloc, NeonFlowState>(
        listener: (context, state) {
          if (state.status == NeonFlowStatus.levelCompleted &&
              state.level != _lastCompletedLevel) {
            _lastCompletedLevel = state.level;
            AnalyticsService.instance.logEvent('level_completed', {
              'game': 'Neon Flow',
              'level': state.level,
            });
            // Show Level Complete Dialog
            _showLevelCompleteDialog(context, state);
          }
        },
        builder: (context, state) {
          // Layout
          final screenWidth = MediaQuery.of(context).size.width;
          final boardValues = screenWidth - 32;
          final isGameOver = state.status == NeonFlowStatus.gameOver;

          return SafeArea(
            child: Column(
              children: [
                _buildHeader(state),
                if (isGameOver)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      border: Border.all(color: Colors.redAccent, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "NO MOVES POSSIBLE!",
                          style: GoogleFonts.pressStart2p(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (state.reviveCount < 2)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amberAccent,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () async {
                              final rewarded = await AdManager.instance
                                  .showRewarded(
                                    onRewardEarned: () {
                                      context.read<NeonFlowBloc>().add(
                                        const NeonFlowRevived(),
                                      );
                                    },
                                    rewardType: 'revive',
                                  );
                              if (!rewarded && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Ad not ready")),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.play_circle_filled,
                              size: 16,
                            ),
                            label: Text(
                              "REVIVE (AD)",
                              style: GoogleFonts.pressStart2p(fontSize: 10),
                            ),
                          ),
                        if (state.reviveCount >= 2)
                          Text(
                            "GAME OVER",
                            style: GoogleFonts.pressStart2p(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),

                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onPanStart: (details) => _onPanStart(
                        context,
                        details,
                        boardValues,
                        state.size,
                      ),
                      onPanUpdate: (details) => _onPanUpdate(
                        context,
                        details,
                        boardValues,
                        state.size,
                      ),
                      onPanEnd: (details) => context.read<NeonFlowBloc>().add(
                        const NeonFlowDragEnded(),
                      ),
                      child: SizedBox(
                        width: boardValues,
                        height: boardValues,
                        child: CustomPaint(
                          painter: FlowPainter(state),
                          isComplex: true,
                          willChange: true,
                        ),
                      ),
                    ),
                  ),
                ),
                const AdBanner(),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onPanStart(
    BuildContext context,
    DragStartDetails details,
    double size,
    int gridSize,
  ) {
    if (context.read<NeonFlowBloc>().state.status == NeonFlowStatus.gameOver)
      return;

    final cellSize = size / gridSize;
    final int c = (details.localPosition.dx / cellSize).floor();
    final int r = (details.localPosition.dy / cellSize).floor();

    if (c >= 0 && c < gridSize && r >= 0 && r < gridSize) {
      context.read<NeonFlowBloc>().add(NeonFlowDragStarted(r, c));
    }
  }

  void _onPanUpdate(
    BuildContext context,
    DragUpdateDetails details,
    double size,
    int gridSize,
  ) {
    if (context.read<NeonFlowBloc>().state.status == NeonFlowStatus.gameOver)
      return;

    final cellSize = size / gridSize;
    final int c = (details.localPosition.dx / cellSize).floor();
    final int r = (details.localPosition.dy / cellSize).floor();

    // Allow dragging precisely
    context.read<NeonFlowBloc>().add(NeonFlowDragUpdated(r, c));
  }

  Widget _buildHeader(NeonFlowState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "NEON FLOW",
                style: GoogleFonts.pressStart2p(
                  color: Colors.cyanAccent,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "LEVEL ${state.level}",
                style: GoogleFonts.pressStart2p(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // IconButton(
              //   icon: const Icon(
              //     Icons.lightbulb_outline,
              //     color: Colors.amberAccent,
              //   ),
              //   onPressed: () async {
              //     if (state.status == NeonFlowStatus.gameOver) return;
              //
              //     final rewarded = await AdManager.instance.showRewarded(
              //       onRewardEarned: () {
              //         context.read<NeonFlowBloc>().add(const NeonFlowHint());
              //       },
              //       rewardType: 'hint',
              //     );
              //     if (!rewarded && context.mounted) {
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         const SnackBar(content: Text("Ad not ready")),
              //       );
              //     }
              //   },
              // ),
              // const SizedBox(width: 16),
              // IconButton(
              //   icon: const Icon(Icons.refresh, color: Colors.white),
              //   onPressed: () {
              //     context.read<NeonFlowBloc>().add(
              //       const NeonFlowRestartLevel(),
              //     );
              //   },
              // ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "BEST",
                    style: GoogleFonts.pressStart2p(
                      color: Colors.amberAccent,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${state.highScore}",
                    style: GoogleFonts.pressStart2p(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "SCORE",
                    style: GoogleFonts.pressStart2p(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${state.score}",
                    style: GoogleFonts.pressStart2p(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLevelCompleteDialog(BuildContext context, NeonFlowState state) {
    // Persistent dialog - No auto-advance
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF16213e),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.cyanAccent, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(
            child: Text(
              "LEVEL ${state.level}\nCOMPLETE!",
              textAlign: TextAlign.center,
              style: GoogleFonts.pressStart2p(
                color: Colors.greenAccent,
                fontSize: 20,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                "Score: +${state.level * 100}",
                style: GoogleFonts.pressStart2p(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                onPressed: () {
                  // Close dialog
                  Navigator.of(dialogContext).pop();
                  // Trigger next level
                  context.read<NeonFlowBloc>().add(const NeonFlowNextLevel());
                },
                child: Text(
                  "NEXT LEVEL",
                  style: GoogleFonts.pressStart2p(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
