import 'dart:math';
import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  int get totalLevels {
    final unlocked = ProgressService.instance.unlockedLevel;
    // Always provide at least 30 levels and expand infinitely in batches of 12
    return max(30, ((unlocked + 15) ~/ 6) * 6);
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    final totalStars = progress.getTotalStars();
    final maxStars = progress.unlockedLevel * 3;

    return Scaffold(
      body: Stack(
        children: [
          // Background whimsical purple sky
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3B0764), // Deep Purple
                  Color(0xFF1E1B4B), // Indigo Night
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5252).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'CANDY MAP 🗺️',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      // Total Stars Collected Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 5),
                            Text(
                              '$totalStars / $maxStars',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Level Cards Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 18,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: totalLevels,
                    itemBuilder: (context, index) {
                      final levelNum = index + 1;
                      final isUnlocked = progress.isLevelUnlocked(levelNum);
                      final stars = progress.getStarsForLevel(levelNum);
                      final highScore = progress.getHighScoreForLevel(levelNum);

                      return _buildCandyLevelNode(
                        levelNumber: levelNum,
                        isUnlocked: isUnlocked,
                        stars: stars,
                        highScore: highScore,
                        onTap: () async {
                          if (isUnlocked) {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => GameScreen(initialLevel: levelNum),
                              ),
                            );
                            setState(() {});
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandyLevelNode({
    required int levelNumber,
    required bool isUnlocked,
    required int stars,
    required int highScore,
    required VoidCallback onTap,
  }) {
    // Alternate pleasant candy colors for level buttons
    final candyColors = [
      const [Color(0xFF38BDF8), Color(0xFF0284C7)], // Sky Blue
      const [Color(0xFFF472B6), Color(0xFFDB2777)], // Pink
      const [Color(0xFF34D399), Color(0xFF059669)], // Mint Green
      const [Color(0xFFFBBF24), Color(0xFFD97706)], // Gold Orange
      const [Color(0xFFA78BFA), Color(0xFF7C3AED)], // Purple
    ];
    final activeGradient = candyColors[(levelNumber - 1) % candyColors.length];

    return InkWell(
      onTap: isUnlocked ? onTap : null,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: activeGradient,
                )
              : const LinearGradient(
                  colors: [Color(0xFF334155), Color(0xFF1E293B)],
                ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUnlocked ? Colors.white : Colors.white12,
            width: isUnlocked ? 2.5 : 1.2,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: activeGradient.first.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!isUnlocked)
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    color: Color(0xFF94A3B8),
                    size: 28,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'LOCKED',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Number circle
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$levelNumber',
                      style: TextStyle(
                        color: activeGradient.last,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Stars row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final earned = i < stars;
                      return Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: earned ? const Color(0xFFFFD54F) : Colors.white30,
                        shadows: earned
                            ? [
                                const Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      );
                    }),
                  ),

                  if (highScore > 0)
                    Text(
                      '$highScore pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
