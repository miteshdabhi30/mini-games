import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_object/games/number_merge/bloc/number_merge_bloc.dart';
import 'package:green_object/games/number_merge/bloc/number_merge_event.dart';
import 'package:green_object/games/number_merge/bloc/number_merge_state.dart';
import 'package:green_object/ui/widgets/ad_rectangle.dart';
import 'package:green_object/utils/ad_manager.dart';

class NumberMergeScreen extends StatelessWidget {
  const NumberMergeScreen({super.key});

  static Route route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => NumberMergeBloc()..add(const NumberMergeStarted()),
        child: const NumberMergeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NumberMergeBloc, NumberMergeState>(
      listener: (context, state) {
        if (state.status == NumberMergeStatus.gameOver) {
          AdManager.instance.onGameOver();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF1a1a2e),
          body: state.status == NumberMergeStatus.gameOver
              ? _buildGameOver(context, state)
              : _buildGame(context, state),
        );
      },
    );
  }

  Widget _buildGame(BuildContext context, NumberMergeState state) {
    if (state.status == NumberMergeStatus.initial || state.grid.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Column(
        children: [
          // Header
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
                // Next Number Indicator
                Column(
                  children: [
                    Text(
                      'NEXT',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 10,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _NumberTile(
                      value: state.nextNumber,
                      size: 40,
                      fontSize: 14,
                    ),
                  ],
                ),
                Column(
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
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildGrid(context, state),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, NumberMergeState state) {
    return Row(
      children: List.generate(NumberMergeBloc.cols, (colIndex) {
        return Expanded(
          child: GestureDetector(
            onTap: () {
              context.read<NumberMergeBloc>().add(
                NumberMergeColumnTapped(colIndex),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  right: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: List.generate(NumberMergeBloc.rows, (rowIndex) {
                  final val = state.grid[colIndex][rowIndex];
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: val > 0
                          ? _NumberTile(
                              value: val,
                              size: double.infinity,
                              fontSize: 18,
                            )
                          : null,
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGameOver(BuildContext context, NumberMergeState state) {
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
                          color: Colors.amberAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'SCORE',
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
                                'HIGH',
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        context.read<NumberMergeBloc>().add(
                          const NumberMergeRestarted(),
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
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'HOME',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 10,
                          color: Colors.white60,
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
    );
  }
}

class _NumberTile extends StatelessWidget {
  final int value;
  final double size;
  final double fontSize;

  const _NumberTile({
    required this.value,
    required this.size,
    required this.fontSize,
  });

  Color _getColor(int value) {
    switch (value) {
      case 2:
        return Colors.blueAccent;
      case 4:
        return Colors.greenAccent;
      case 8:
        return Colors.orangeAccent;
      case 16:
        return Colors.redAccent;
      case 32:
        return Colors.purpleAccent;
      case 64:
        return Colors.pinkAccent;
      case 128:
        return Colors.tealAccent;
      case 256:
        return Colors.indigoAccent;
      case 512:
        return Colors.deepOrangeAccent;
      case 1024:
        return Colors.limeAccent;
      case 2048:
        return Colors.amberAccent;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getColor(value).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getColor(value), width: 2),
        boxShadow: [
          BoxShadow(
            color: _getColor(value).withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          value.toString(),
          style: GoogleFonts.pressStart2p(
            fontSize: value > 1000 ? fontSize * 0.7 : fontSize,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
