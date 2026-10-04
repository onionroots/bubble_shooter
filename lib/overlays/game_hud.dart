import 'package:flutter/material.dart';
import '../models/bubble_color.dart';
import '../models/level_data.dart';
import '../services/progress_service.dart';

class GameHud extends StatelessWidget {
  final LevelData levelData;
  final int score;
  final int shotsLeft;
  final int combo;
  final BubbleType currentBubble;
  final BubbleType nextBubble;
  final VoidCallback onPause;
  final VoidCallback onSwap;
  final VoidCallback onUseBomb;
  final VoidCallback onUseRainbow;

  const GameHud({
    super.key,
    required this.levelData,
    required this.score,
    required this.shotsLeft,
    required this.combo,
    required this.currentBubble,
    required this.nextBubble,
    required this.onPause,
    required this.onSwap,
    required this.onUseBomb,
    required this.onUseRainbow,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;

    // Calculate star progress
    final double starProgress = (score / levelData.star3Score).clamp(0.0, 1.0);
    final bool hasStar1 = score >= levelData.star1Score;
    final bool hasStar2 = score >= levelData.star2Score;
    final bool hasStar3 = score >= levelData.star3Score;

    return SafeArea(
      child: Stack(
        children: [
          // Top Compact HUD Header Bar
          Positioned(
            top: 6,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pause Button
                _buildToyButton(
                  icon: Icons.pause_rounded,
                  color: const Color(0xFFFF5252),
                  onTap: onPause,
                ),

                // Center Compact Pill: Level, Score & Stars (All in one row!)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFC4B5FD), width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Level Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFFD97706),
                              offset: Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: Text(
                          'LVL ${levelData.levelNumber}',
                          style: const TextStyle(
                            color: Color(0xFF78350F),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Score
                      Text(
                        '$score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 3 Mini Stars
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: hasStar1 ? const Color(0xFFFFD54F) : Colors.white24,
                          ),
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: hasStar2 ? const Color(0xFFFFD54F) : Colors.white24,
                          ),
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: hasStar3 ? const Color(0xFFFFD54F) : Colors.white24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Shots Left Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bubble_chart_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$shotsLeft',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Big Combo Banner
          if (combo > 1)
            Positioned(
              top: 86,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF2E63), Color(0xFFFF8A00)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2E63).withValues(alpha: 0.6),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        '${combo}X COMBO POWER!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Left: Next Bubble Preview & Swap Button
          Positioned(
            bottom: 20,
            left: 16,
            child: InkWell(
              onTap: onSwap,
              borderRadius: BorderRadius.circular(26),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.white, width: 2.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMiniKawaiiBubble(nextBubble),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'NEXT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          'Swap',
                          style: TextStyle(
                            color: Color(0xFFE0F2FE),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.swap_vert_rounded,
                        color: Color(0xFF0284C7),
                        size: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Right: Booster Power-Up Tray (BOMB & RAINBOW)
          Positioned(
            bottom: 20,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 💣 BOMB BUSTER BUTTON
                _buildBoosterButton(
                  title: 'BOMB',
                  icon: Icons.local_fire_department_rounded,
                  count: progress.bombBoosters,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5252), Color(0xFFD50000)],
                  ),
                  borderColor: const Color(0xFFFF8A80),
                  onTap: onUseBomb,
                ),
                const SizedBox(width: 10),
                // 🌈 RAINBOW CANDY BUTTON
                _buildBoosterButton(
                  title: 'MAGIC',
                  icon: Icons.auto_awesome_rounded,
                  count: progress.rainbowBoosters,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA855F7), Color(0xFF7E22CE)],
                  ),
                  borderColor: const Color(0xFFE9D5FF),
                  onTap: onUseRainbow,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoosterButton({
    required String title,
    required IconData icon,
    required int count,
    required LinearGradient gradient,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    final bool hasStock = count > 0;

    return InkWell(
      onTap: hasStock ? onTap : null,
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: hasStock
                  ? gradient
                  : const LinearGradient(
                      colors: [Color(0xFF475569), Color(0xFF334155)],
                    ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: hasStock ? borderColor : Colors.white24,
                width: 2.2,
              ),
              boxShadow: hasStock
                  ? [
                      BoxShadow(
                        color: borderColor.withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: hasStock ? Colors.white : Colors.white38,
              size: 26,
            ),
          ),
          // Count Badge (Pill)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasStock ? const Color(0xFFFBBF24) : const Color(0xFF64748B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 4),
                ],
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToyButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildMiniKawaiiBubble(BubbleType type) {
    final colorData = BubbleColorData.get(type);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            colorData.highlightColor,
            colorData.baseColor,
            colorData.shadowColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorData.baseColor.withValues(alpha: 0.6),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: colorData.icon != null
            ? Icon(colorData.icon, size: 16, color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 3.5),
                  Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
