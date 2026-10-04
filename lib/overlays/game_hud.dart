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
  final double feverProgress;
  final bool isFeverMode;
  final VoidCallback onPause;
  final VoidCallback onSwap;
  final VoidCallback onUseBomb;
  final VoidCallback onUseRainbow;
  final VoidCallback onUseFireball;

  const GameHud({
    super.key,
    required this.levelData,
    required this.score,
    required this.shotsLeft,
    required this.combo,
    required this.currentBubble,
    required this.nextBubble,
    this.feverProgress = 0.0,
    this.isFeverMode = false,
    required this.onPause,
    required this.onSwap,
    required this.onUseBomb,
    required this.onUseRainbow,
    required this.onUseFireball,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;

    // Calculate star progress
    final double starProgress = (score / levelData.star3Score).clamp(0.0, 1.0);
    final bool hasStar1 = score >= levelData.star1Score;
    final bool hasStar2 = score >= levelData.star2Score;
    final bool hasStar3 = score >= levelData.star3Score;
    final bool lowShots = shotsLeft <= 5;

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

                // Center Compact Pill: Level, Score, Stars & star-progress bar
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF9F7AEA), Color(0xFF6D28D9), Color(0xFF4C1D95)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFC4B5FD), width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
                        blurRadius: 14,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Level Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFFDE68A), Color(0xFFFBBF24)],
                              ),
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
                          // Score (animated count-up)
                          TweenAnimationBuilder<double>(
                            tween: Tween(end: score.toDouble()),
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) => Text(
                              '${value.round()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(color: Color(0xFF2E1065), offset: Offset(0, 1.5)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 3 Mini Stars
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHudStar(hasStar1),
                              _buildHudStar(hasStar2),
                              _buildHudStar(hasStar3),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      _buildStarProgressBar(starProgress),
                    ],
                  ),
                ),

                // Shots Left Badge (turns red & glows when running low)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: lowShots
                          ? const [Color(0xFFFF6B6B), Color(0xFFD50000)]
                          : const [Color(0xFFFBBF24), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: lowShots ? const Color(0xFFFFCDD2) : const Color(0xFFFDE68A),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (lowShots ? const Color(0xFFFF1744) : const Color(0xFFF59E0B))
                            .withValues(alpha: lowShots ? 0.7 : 0.45),
                        blurRadius: lowShots ? 14 : 8,
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
                      // Bounce the number every time a shot is used
                      TweenAnimationBuilder<double>(
                        key: ValueKey('shots_$shotsLeft'),
                        tween: Tween(begin: 1.4, end: 1.0),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.elasticOut,
                        builder: (context, s, child) =>
                            Transform.scale(scale: s, child: child),
                        child: Text(
                          '$shotsLeft',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Animated Fever Mode Status & Meter Bar
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: isFeverMode
                  ? TweenAnimationBuilder<double>(
                      key: const ValueKey('fever_active_banner'),
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) => Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF007F), Color(0xFFFF8A00), Color(0xFFFFD700)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF007F).withValues(alpha: 0.75),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '⚡ 2X FEVER: ${(feverProgress * 8).ceil()}s ⚡',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : feverProgress > 0.05
                      ? Container(
                          width: 140,
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFF8A00).withValues(alpha: 0.6),
                              width: 1.2,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              FractionallySizedBox(
                                widthFactor: feverProgress.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF007F), Color(0xFFFF8A00), Color(0xFFFFD700)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF8A00).withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.bolt_rounded, color: Colors.white, size: 12),
                                    Text(
                                      'FEVER ${(feverProgress * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          ),

          // Big Combo Banner (elastic pop-in each time the combo grows)
          if (combo > 1)
            Positioned(
              top: 96,
              left: 0,
              right: 0,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('combo_$combo'),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, t, child) => Transform.scale(
                    scale: 0.4 + 0.6 * t,
                    child: Transform.rotate(angle: (1 - t) * -0.15, child: child),
                  ),
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

          // Bottom Right: Booster Power-Up Tray (BOMB, MAGIC & FIREBALL)
          Positioned(
            bottom: 20,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 💣 BOMB BOOSTER
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
                const SizedBox(width: 8),
                // 🌈 RAINBOW BOOSTER
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
                const SizedBox(width: 8),
                // 🔥 FIREBALL BOOSTER
                _buildBoosterButton(
                  title: 'FIRE',
                  icon: Icons.whatshot_rounded,
                  count: progress.fireballBoosters,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF3D00), Color(0xFFDD2C00)],
                  ),
                  borderColor: const Color(0xFFFF9E80),
                  onTap: onUseFireball,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudStar(bool earned) {
    return AnimatedScale(
      scale: earned ? 1.15 : 0.9,
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      child: Icon(
        Icons.star_rounded,
        size: 16,
        color: earned ? const Color(0xFFFFD54F) : Colors.white24,
        shadows: earned
            ? const [Shadow(color: Color(0xFFFFA000), blurRadius: 8)]
            : null,
      ),
    );
  }

  Widget _buildStarProgressBar(double progress) {
    const double barWidth = 150;
    final m1 = (levelData.star1Score / levelData.star3Score).clamp(0.0, 1.0);
    final m2 = (levelData.star2Score / levelData.star3Score).clamp(0.0, 1.0);

    return SizedBox(
      width: barWidth,
      height: 7,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Track
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2E1065),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Animated fill
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Container(
              width: barWidth * v,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFFFF6F00)],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          // Star threshold markers
          for (final m in [m1, m2])
            Positioned(
              left: barWidth * m - 1,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: Colors.white54),
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
            width: 48,
            height: 48,
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
