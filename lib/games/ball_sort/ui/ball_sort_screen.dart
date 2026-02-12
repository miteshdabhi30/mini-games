import 'package:flutter/material.dart';
import 'package:green_object/services/analytics_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_object/games/ball_sort/bloc/ball_sort_bloc.dart';
import 'package:green_object/games/ball_sort/bloc/ball_sort_event.dart';
import 'package:green_object/games/ball_sort/bloc/ball_sort_state.dart';
import 'package:green_object/ui/widgets/ad_rectangle.dart';
import 'package:green_object/utils/ad_manager.dart';

class BallSortScreen extends StatefulWidget {
  const BallSortScreen({super.key});

  static Route route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => BallSortBloc()..add(const BallSortStarted()),
        child: const BallSortScreen(),
      ),
    );
  }

  @override
  State<BallSortScreen> createState() => _BallSortScreenState();
}

class _BallSortScreenState extends State<BallSortScreen> {
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    AnalyticsService.instance.logGameStart('Ball Sort');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: Text("BALL SORT", style: GoogleFonts.pressStart2p(fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          BlocBuilder<BallSortBloc, BallSortState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.undo),
                onPressed: state.history.isNotEmpty
                    ? () =>
                          context.read<BallSortBloc>().add(const BallSortUndo())
                    : null,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<BallSortBloc>().add(const BallSortRestarted()),
          ),
        ],
      ),
      body: BlocConsumer<BallSortBloc, BallSortState>(
        listener: (context, state) {
          if (state.status == BallSortStatus.levelCompleted) {
            // Show Win Dialog
            AdManager.instance.onGameOver(); // Reusing full screen ad logic
            AnalyticsService.instance.logGameEnd(
              'Ball Sort',
              state.level,
              DateTime.now().difference(_startTime).inSeconds,
            );
            // Reset timer for next level? or wait until next level starts?
            // When 'Next Level' is clicked, it sends BallSortNextLevel.
            // Status changes to playing?
            // I should reset timer when level changes.
            _startTime =
                DateTime.now(); // Reset for next level measurement from now (idle time included? maybe ok)

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF16213e),
                title: Text(
                  "LEVEL CLEARED!",
                  style: GoogleFonts.pressStart2p(
                    color: Colors.greenAccent,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Moves: ${state.moves}",
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 250, child: AdRectangle()),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      context.read<BallSortBloc>().add(
                        const BallSortNextLevel(),
                      );
                    },
                    child: Text(
                      "NEXT LEVEL",
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else if (state.status == BallSortStatus.gameOver) {
            // Show Game Over / No Moves Dialog
            AdManager.instance.onGameOver();
            AnalyticsService.instance.logGameEnd(
              'Ball Sort',
              state.level,
              DateTime.now().difference(_startTime).inSeconds,
            );

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF16213e),
                title: Text(
                  "NO MOVES!",
                  style: GoogleFonts.pressStart2p(
                    color: Colors.redAccent,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "You're stuck!",
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!state.reviveUsed)
                      OutlinedButton(
                        onPressed: () async {
                          Navigator.of(
                            context,
                          ).pop(); // Close dialog to show ad? Or show ad then close?
                          final rewarded = await AdManager.instance
                              .showRewarded(
                                onRewardEarned: () {
                                  context.read<BallSortBloc>().add(
                                    const BallSortRevived(),
                                  );
                                },
                                rewardType: 'revive',
                              );
                          if (!rewarded) {
                            // If ad fails, keep dialog open?
                            // For now, assume success or just close.
                            // Ideally show snackbar.
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.amberAccent),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          "WATCH AD\n+1 TUBE",
                          style: GoogleFonts.pressStart2p(
                            color: Colors.amberAccent,
                            fontSize: 10,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (state.reviveUsed)
                      Text(
                        "No more revives!",
                        style: GoogleFonts.pressStart2p(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.read<BallSortBloc>().add(
                          const BallSortRestarted(),
                        );
                      },
                      child: Text(
                        "RESTART LEVEL",
                        style: GoogleFonts.pressStart2p(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(height: 250, child: AdRectangle()),
                  ],
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "LEVEL ${state.level}",
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "MOVES: ${state.moves}",
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
                  child: SingleChildScrollView(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 40,
                      children: List.generate(state.tubes.length, (index) {
                        return _buildTube(context, state, index);
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTube(BuildContext context, BallSortState state, int index) {
    final tube = state.tubes[index];
    final isSelected = state.selectedTubeIndex == index;

    return GestureDetector(
      onTap: () {
        context.read<BallSortBloc>().add(BallSortTubeTapped(index));
      },
      child: Column(
        children: [
          // Floating ball (if selected)
          if (isSelected && tube.isNotEmpty)
            _buildBall(tube.last, isSelected: true),
          if (!isSelected || tube.isEmpty)
            const SizedBox(height: 40), // Placeholder height for selected ball

          Container(
            width: 50,
            height: 200, // 4 balls * 40 + padding
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: isSelected ? Colors.yellowAccent : Colors.white54,
                width: 2,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Balls inside tube
                // Note: tube list is from bottom to top?
                // If I use standard add/removeLast, index 0 is bottom.
                // But Column renders top down.
                // So I need to reverse the list for rendering?
                // If ball 0 is bottom, ball N is top.
                // In Column, I want Top -> Bottom.
                // So I render: [Space], [Ball], [Ball], [Ball].
                // Wait, if I use MainAxisAlignment.end, it fills from bottom.
                // So children should be ordered top-to-bottom?
                // tube[0] is bottom-most (first added).
                // tube[last] is top-most.
                // In a Column with MainAxisAlignment.end:
                // The LAST child is at the bottom.
                // So I should render tube children in reverse order?
                // Let's check:
                // Child 1 (Top)
                // Child 2
                // ...
                // Child N (Bottom) -> MainAxisAlignment.end pushes everything down.
                // So Child N is at bottom.
                // tube[0] is bottom ball. So tube[0] should be Last child.
                // Correct.
                // BUT, if selected, I don't render the top ball inside the tube!
                ...List.generate(isSelected ? tube.length - 1 : tube.length, (
                  i,
                ) {
                  // We need to map index correctly.
                  // If isSelected, we skip the last ball (top one).
                  // tube indices: 0 (bottom), 1, 2 (top).
                  // If selected, we render 0 and 1.
                  // In Column (reversed for visual):
                  // we want 1 (top-most in tube), then 0.
                  // So we iterate reversed.

                  int ballIndex =
                      (isSelected ? tube.length - 1 : tube.length) - 1 - i;
                  return _buildBall(tube[ballIndex]);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBall(Color color, {bool isSelected = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isSelected ? 10 : 4),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
    );
  }
}
