import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/bubble_shooter_game.dart';
import '../models/bubble_color.dart';
import '../models/level_data.dart';
import '../overlays/game_hud.dart';
import '../overlays/level_complete_dialog.dart';
import '../overlays/level_failed_dialog.dart';
import '../overlays/pause_dialog.dart';
import '../services/progress_service.dart';

class GameScreen extends StatefulWidget {
  final int initialLevel;

  const GameScreen({
    super.key,
    required this.initialLevel,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late int currentLevelNumber;
  late LevelData levelData;
  late BubbleShooterGame game;

  int score = 0;
  int shotsLeft = 0;
  int combo = 0;
  BubbleType currentBubble = BubbleType.red;
  BubbleType nextBubble = BubbleType.blue;

  bool isFeverMode = false;
  double feverProgress = 0.0;

  int earnedStars = 0;
  String failReason = 'Out of shots!';

  @override
  void initState() {
    super.initState();
    currentLevelNumber = widget.initialLevel;

    ProgressService.instance.onAchievementUnlocked = (title, desc) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E1B4B),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
          ),
          content: Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      desc,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'BADGE! 🎖️',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    };

    _startLevel(currentLevelNumber);
  }

  void _startLevel(int level) {
    currentLevelNumber = level;
    levelData = LevelData.getLevel(level);
    score = 0;
    shotsLeft = levelData.maxShots;
    combo = 0;
    earnedStars = 0;
    isFeverMode = false;
    feverProgress = 0.0;

    game = BubbleShooterGame(
      levelData: levelData,
      onScoreChanged: (s) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => score = s);
        });
      },
      onShotsChanged: (sh) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => shotsLeft = sh);
        });
      },
      onComboChanged: (c) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => combo = c);
        });
      },
      onCurrentBubbleChanged: (b) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => currentBubble = b);
        });
      },
      onNextBubbleChanged: (b) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => nextBubble = b);
        });
      },
      onFeverChanged: (active, prog) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              isFeverMode = active;
              feverProgress = prog;
            });
          }
        });
      },
      onLevelComplete: (stars, finalScore) async {
        earnedStars = stars;
        await ProgressService.instance.completeLevel(
          currentLevelNumber,
          finalScore,
          stars,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            game.overlays.add('complete');
          }
        });
      },
      onLevelFailed: (reason) {
        failReason = reason;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            game.overlays.add('failed');
          }
        });
      },
    );
  }

  void _nextLevel() {
    game.overlays.remove('complete');
    setState(() {
      _startLevel(currentLevelNumber + 1);
    });
  }

  void _replayLevel() {
    game.overlays.remove('complete');
    game.overlays.remove('failed');
    game.overlays.remove('pause');

    // Generate a fresh new bubble board layout on each retry/replay!
    levelData = LevelData.getLevel(currentLevelNumber);
    game.restartLevel(levelData);

    setState(() {
      score = 0;
      shotsLeft = levelData.maxShots;
      combo = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Stack(
        children: [
          GameWidget<BubbleShooterGame>(
            key: ValueKey('bubble_game_$currentLevelNumber'),
            game: game,
            initialActiveOverlays: const ['hud'],
            overlayBuilderMap: {
              'hud': (context, g) => GameHud(
                    levelData: levelData,
                    score: score,
                    shotsLeft: shotsLeft,
                    combo: combo,
                    currentBubble: currentBubble,
                    nextBubble: nextBubble,
                    isFeverMode: isFeverMode,
                    feverProgress: feverProgress,
                    onPause: () {
                      g.overlays.add('pause');
                      g.pauseEngine();
                    },
                    onSwap: () {
                      g.swapBubbles();
                    },
                    onUseBomb: () {
                      if (ProgressService.instance.useBombBooster()) {
                        g.equipBooster(BubbleType.bomb);
                        setState(() {});
                      }
                    },
                    onUseRainbow: () {
                      if (ProgressService.instance.useRainbowBooster()) {
                        g.equipBooster(BubbleType.rainbow);
                        setState(() {});
                      }
                    },
                    onUseFireball: () {
                      if (ProgressService.instance.useFireballBooster()) {
                        g.equipBooster(BubbleType.fireball);
                        setState(() {});
                      }
                    },
                  ),
              'pause': (context, g) => PauseDialog(
                    onResume: () {
                      g.overlays.remove('pause');
                      g.resumeEngine();
                    },
                    onRestart: () {
                      g.resumeEngine();
                      _replayLevel();
                    },
                    onExit: () {
                      g.resumeEngine();
                      Navigator.of(context).pop();
                    },
                  ),
              'complete': (context, g) => LevelCompleteDialog(
                    levelNumber: currentLevelNumber,
                    stars: earnedStars,
                    score: score,
                    highScore: ProgressService.instance.getHighScoreForLevel(currentLevelNumber),
                    onNextLevel: _nextLevel,
                    onReplay: _replayLevel,
                    onLevelSelect: () => Navigator.of(context).pop(),
                  ),
              'failed': (context, g) => LevelFailedDialog(
                    levelNumber: currentLevelNumber,
                    reason: failReason,
                    score: score,
                    onRetry: _replayLevel,
                    onLevelSelect: () => Navigator.of(context).pop(),
                  ),
            },
          ),
        ],
      ),
    );
  }
}
