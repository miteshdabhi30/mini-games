import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/bloc/game_bloc.dart';
import 'package:green_object/ui/widgets/ad_rectangle.dart';
import 'package:green_object/utils/ad_manager.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
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
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFe94560),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<GameBloc, GameState>(
                      builder: (context, state) {
                        return Text(
                          "Final Score: ${state.score.toInt()}",
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<GameBloc, GameState>(
                      builder: (context, state) {
                        return Text(
                          "High Score: ${state.highScore}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white54,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        context.read<GameBloc>().add(GameRestarted());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0f3460),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "TRY AGAIN",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                    BlocBuilder<GameBloc, GameState>(
                      buildWhen: (previous, current) =>
                          previous.reviveUsed != current.reviveUsed,
                      builder: (context, state) {
                        if (state.reviveUsed) return const SizedBox.shrink();
                        return Column(
                          children: [
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () async {
                                final rewarded = await AdManager.instance
                                    .showRewarded(
                                      onRewardEarned: () {
                                        context.read<GameBloc>().add(
                                          GameRevived(),
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
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white70),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                "WATCH AD TO CONTINUE",
                                style: TextStyle(color: Colors.white),
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
            // Large rectangular ad anchored at the bottom
            SizedBox(height: 330, child: const AdRectangle()),
          ],
        ),
      ),
    );
  }
}
