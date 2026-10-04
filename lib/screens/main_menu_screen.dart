import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bubble_color.dart';
import '../services/progress_service.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;

    return Scaffold(
      body: Stack(
        children: [
          // Whimsical Candy Sky Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4C1D95), // Magical Violet
                  Color(0xFF831843), // Candy Magenta
                  Color(0xFF1E1B4B), // Deep Night Purple
                ],
              ),
            ),
          ),

          // Floating Animated Kawaii Bubbles in background
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Stack(
                children: [
                  _buildKawaiiBubble(
                    top: 60 + 18 * sin(_animController.value * 2 * pi),
                    left: 30,
                    size: 74,
                    type: BubbleType.blue,
                  ),
                  _buildKawaiiBubble(
                    top: 130 + 22 * cos(_animController.value * 2 * pi),
                    right: 35,
                    size: 88,
                    type: BubbleType.pink,
                  ),
                  _buildKawaiiBubble(
                    bottom: 140 + 20 * sin((_animController.value + 0.5) * 2 * pi),
                    left: 45,
                    size: 80,
                    type: BubbleType.green,
                  ),
                  _buildKawaiiBubble(
                    bottom: 210 + 25 * cos(_animController.value * 2 * pi),
                    right: 50,
                    size: 72,
                    type: BubbleType.yellow,
                  ),
                  _buildKawaiiBubble(
                    top: 270 + 16 * sin(_animController.value * pi),
                    left: 100,
                    size: 55,
                    type: BubbleType.purple,
                  ),
                ],
              );
            },
          ),

          // Main UI Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Top Status: Star Bank & Sound Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 6),
                            Text(
                              '${progress.getTotalStars()} Stars',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          progress.toggleSound();
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30, width: 2),
                          ),
                          child: Icon(
                            progress.soundEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // Giant Center Mascot Bubble (Waving at child!)
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      final bounce = sin(_animController.value * 2 * pi) * 10;
                      return Transform.translate(
                        offset: Offset(0, bounce),
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              center: Alignment(-0.35, -0.4),
                              colors: [
                                Color(0xFFFF8DA1),
                                Color(0xFFFF2E63),
                                Color(0xFF9E002B),
                              ],
                            ),
                            border: Border.all(color: Colors.white, width: 3.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF2E63).withValues(alpha: 0.65),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Kawaii Eyes
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildMascotEye(),
                                  const SizedBox(width: 22),
                                  _buildMascotEye(),
                                ],
                              ),
                              // Blush Cheeks
                              Positioned(
                                bottom: 42,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    const SizedBox(width: 50),
                                    Container(
                                      width: 18,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Big Happy Smile
                              Positioned(
                                bottom: 32,
                                child: Container(
                                  width: 26,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E293B),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // Game Title Banner
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFF176), Color(0xFFFF8A00), Color(0xFFFF2E63)],
                    ).createShader(bounds),
                    child: const Text(
                      'BUBBLE POP',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Text(
                    'CANDY ADVENTURE',
                    style: TextStyle(
                      color: Color(0xFF67E8F9),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.5,
                      shadows: [
                        Shadow(
                          color: Color(0xFF06B6D4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Giant 3D "PLAY" Button (Inviting, tactile, bouncy!)
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      final scale = 1.0 + 0.03 * sin(_animController.value * 2 * pi);
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => GameScreen(
                              initialLevel: progress.unlockedLevel,
                            ),
                          ),
                        );
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(66),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                          side: const BorderSide(color: Color(0xFF6EE7B7), width: 3),
                        ),
                        elevation: 10,
                        shadowColor: const Color(0xFF10B981).withValues(alpha: 0.7),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFF059669),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'PLAY LEVEL ${progress.unlockedLevel}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // "CHOOSE LEVEL" Secondary Button
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LevelSelectScreen(),
                        ),
                      );
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                        side: const BorderSide(color: Colors.white, width: 2.2),
                      ),
                      elevation: 6,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'LEVEL MAP 🗺️',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Bottom Total Score Ribbon
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'TOTAL SCORE: ${progress.totalScore} 🏆',
                      style: const TextStyle(
                        color: Color(0xFFFDE047),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotEye() {
    return Container(
      width: 20,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 3,
            left: 3,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKawaiiBubble({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required BubbleType type,
  }) {
    final colorData = BubbleColorData.get(type);

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Opacity(
        opacity: 0.5,
        child: Container(
          width: size,
          height: size,
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
                color: colorData.baseColor.withValues(alpha: 0.5),
                blurRadius: 18,
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: size * 0.12,
                  height: size * 0.15,
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: size * 0.12),
                Container(
                  width: size * 0.12,
                  height: size * 0.15,
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
