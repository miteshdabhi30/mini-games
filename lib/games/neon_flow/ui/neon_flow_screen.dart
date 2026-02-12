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

          return SafeArea(
            child: Column(
              children: [
                _buildHeader(state),
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
              IconButton(
                icon: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amberAccent,
                ),
                onPressed: () async {
                  final rewarded = await AdManager.instance.showRewarded(
                    onRewardEarned: () {
                      context.read<NeonFlowBloc>().add(const NeonFlowHint());
                    },
                    rewardType: 'hint',
                  );
                  if (!rewarded && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Ad not ready")),
                    );
                  }
                },
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
    // Auto-advance after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (context.mounted) {
        context.read<NeonFlowBloc>().add(const NeonFlowNextLevel());
      }
    });

    // Show brief success message
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: Text(
          "LEVEL ${state.level} COMPLETE!",
          style: GoogleFonts.pressStart2p(
            color: Colors.greenAccent,
            fontSize: 14,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Score: +${state.level * 100}",
              style: GoogleFonts.pressStart2p(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: Colors.cyanAccent),
          ],
        ),
      ),
    ).then((_) {
      // Close dialog when new level starts
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }
}
