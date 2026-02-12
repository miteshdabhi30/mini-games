import 'package:flutter/material.dart';
import 'package:green_object/services/analytics_service.dart';
import 'package:green_object/ui/game_screen.dart';
import 'package:green_object/games/neon_flow/ui/neon_flow_screen.dart';
import 'package:green_object/games/neon_blaster/ui/neon_blaster_screen.dart';
import 'package:green_object/games/tower_stack/ui/tower_stack_screen.dart';
import 'package:green_object/games/snake/ui/snake_screen.dart';
import 'package:green_object/games/neon_bridge/ui/neon_bridge_screen.dart';
import 'package:green_object/games/math_rush/ui/math_rush_screen.dart';
import 'package:green_object/games/pattern_match/ui/pattern_match_screen.dart';
import 'package:green_object/games/number_merge/ui/number_merge_screen.dart';

import 'package:green_object/games/ball_sort/ui/ball_sort_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('HomeScreen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text("MINI GAMES", style: TextStyle(letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: 10,
          itemBuilder: (context, index) {
            // Game 1: One Button Dodge
            if (index == 0) {
              return _GameCard(
                title: "DODGE",
                color: const Color(0xFFe94560),
                icon: Icons.directions_run,
                onTap: () {
                  AnalyticsService.instance.logEvent('game_selected', {
                    'game': 'Dodge',
                  });
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => GameScreen.route()));
                },
              );
              // Game 2: Neon Maze
            } else if (index == 1) {
              return _GameCard(
                title: "NEON FLOW",
                color: Colors.cyanAccent,
                icon: Icons.timeline,
                onTap: () {
                  AnalyticsService.instance.logEvent('game_selected', {
                    'game': 'Neon Flow',
                  });
                  Navigator.of(context).push(NeonFlowScreen.route());
                },
              );
              // Game 3: Neon Blaster
            } else if (index == 2) {
              return _GameCard(
                title: "NEON BLASTER",
                color: Colors.lightBlueAccent,
                icon: Icons.rocket_launch,
                onTap: () {
                  AnalyticsService.instance.logEvent('game_selected', {
                    'game': 'Neon Blaster',
                  });
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NeonBlasterScreen.route(),
                    ),
                  );
                },
              );
              // Game 4: Tower Stack
            } else if (index == 3) {
              return _GameCard(
                title: "TOWER STACK",
                color: Colors.cyan,
                icon: Icons.layers,
                onTap: () {
                  AnalyticsService.instance.logEvent('game_selected', {
                    'game': 'Tower Stack',
                  });
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TowerStackScreen.route()),
                  );
                },
              );
              // Game 5: Neon Snake
            } else if (index == 4) {
              return _GameCard(
                title: "NEON SNAKE",
                color: Colors.greenAccent,
                icon: Icons.gesture,
                onTap: () {
                  AnalyticsService.instance.logEvent('game_selected', {
                    'game': 'Neon Snake',
                  });
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SnakeScreen.route()),
                  );
                },
              );
              // Game 6: Neon Bridge
            } else if (index == 5) {
              return _GameCard(
                title: "NEON BRIDGE",
                color: Colors.pinkAccent,
                icon: Icons.linear_scale, // Or graphic_eq, or similar
                onTap: () {
                  AnalyticsService.instance.logEvent('game_selected', {
                    'game': 'Neon Bridge',
                  });
                  Navigator.of(context).push(NeonBridgeScreen.route());
                },
              );
              // Game 7: Math Rush
            } else if (index == 6) {
              return _GameCard(
                title: "MATH RUSH",
                color: Colors.amberAccent,
                icon: Icons.calculate,
                onTap: () {
                  AnalyticsService.instance.logEvent('game_selected', {
                    'game': 'Math Rush',
                  });
                  Navigator.of(context).push(MathRushScreen.route());
                },
              );
              // Game 8: Pattern Match
            } else if (index == 7) {
              return _GameCard(
                title: "PATTERN MATCH",
                color: Colors.tealAccent,
                icon: Icons.apps,
                onTap: () {
                  AnalyticsService.instance.logEvent('game_selected', {
                    'game': 'Pattern Match',
                  });
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PatternMatchScreen.route(),
                    ),
                  );
                },
              );
            }
            // Game 9: Number Merge
            else if (index == 8) {
              return _GameCard(
                title: "NUMBER MERGE",
                color: Colors.orangeAccent,
                icon: Icons.view_week,
                onTap: () {
                  AnalyticsService.instance.logEvent('game_selected', {
                    'game': 'Number Merge',
                  });
                  Navigator.of(context).push(NumberMergeScreen.route());
                },
              );
            }
            // Game 10: Ball Sort Puzzle
            else if (index == 9) {
              return _GameCard(
                title: "BALL SORT PUZZLE",
                color: Colors.pinkAccent,
                icon: Icons.sort,
                onTap: () {
                  AnalyticsService.instance.logEvent('game_selected', {
                    'game': 'Ball Sort Puzzle',
                  });
                  Navigator.of(context).push(BallSortScreen.route());
                },
              );
            }
            // Placeholders for future games
            return _GameCard(
              title: "LOCKED",
              color: Colors.white24,
              icon: Icons.lock_outline,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("This game is coming soon!"),
                    duration: Duration(milliseconds: 500),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16213e),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.pressStart2p(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
