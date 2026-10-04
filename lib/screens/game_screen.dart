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

  int earnedStars = 0;
  String failReason = 'Out of shots!';

  @override
  void initState() {
    super.initState();
    currentLevelNumber = widget.initialLevel;
    _startLevel(currentLevelNumber);
  }

  void _startLevel(int level) {
    currentLevelNumber = level;
    levelData = LevelData.getLevel(level);
    score = 0;
    shotsLeft = levelData.maxShots;
    combo = 0;
    earnedStars = 0;

    game = BubbleShooterGame(
      levelData: levelData,
      onScoreChanged: (s) {
        if (mounted) setState(() => score = s);
      },
      onShotsChanged: (sh) {
        if (mounted) setState(() => shotsLeft = sh);
      },
      onComboChanged: (c) {
        if (mounted) setState(() => combo = c);
      },
      onCurrentBubbleChanged: (b) {
        if (mounted) setState(() => currentBubble = b);
      },
      onNextBubbleChanged: (b) {
        if (mounted) setState(() => nextBubble = b);
      },
      onLevelComplete: (stars, finalScore) async {
        earnedStars = stars;
        await ProgressService.instance.completeLevel(
          currentLevelNumber,
          finalScore,
          stars,
        );
        if (mounted) {
          game.overlays.add('complete');
        }
      },
      onLevelFailed: (reason) {
        failReason = reason;
        if (mounted) {
          game.overlays.add('failed');
        }
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
