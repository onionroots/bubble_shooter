import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../models/bubble_color.dart';
import '../models/level_data.dart';
import 'aim_line_component.dart';
import 'bubble_component.dart';
import 'bubble_grid.dart';
import 'cannon_component.dart';
import 'falling_bubble.dart';
import 'particle_effects.dart';
import 'projectile_bubble.dart';

class BubbleShooterGame extends FlameGame with PanDetector {
  LevelData levelData;

  // Callbacks for Flutter HUD & Overlays
  final void Function(int score)? onScoreChanged;
  final void Function(int shots)? onShotsChanged;
  final void Function(int combo)? onComboChanged;
  final void Function(BubbleType next)? onNextBubbleChanged;
  final void Function(BubbleType current)? onCurrentBubbleChanged;
  final void Function(int stars, int score)? onLevelComplete;
  final void Function(String reason)? onLevelFailed;

  late BubbleGrid grid;
  late Vector2 cannonPos;
  late AimLineComponent aimLine;
  late CannonComponent cannon;
  BubbleComponent? readyBubbleComponent;

  final Map<GridSlot, BubbleComponent> _gridBubbles = {};
  ProjectileBubble? _activeProjectile;

  late BubbleType currentBubble;
  late BubbleType nextBubble;

  int score = 0;
  int remainingShots = 0;
  int combo = 0;

  bool isShooting = false;
  bool isGameOver = false;
  bool isLevelWon = false;

  final Random _random = Random();

  // Floating background clouds & stars
  final List<_DriftingCloud> _clouds = [];
  final List<Offset> _twinkles = [];

  BubbleShooterGame({
    required this.levelData,
    this.onScoreChanged,
    this.onShotsChanged,
    this.onComboChanged,
    this.onNextBubbleChanged,
    this.onCurrentBubbleChanged,
    this.onLevelComplete,
    this.onLevelFailed,
  });

  @override
  Color backgroundColor() => const Color(0xFF1E1035); // Whimsical rich twilight

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final gameW = size.x;
    final gameH = size.y;

    // Cannon sits near bottom center
    cannonPos = Vector2(gameW / 2, gameH - 85);

    // Initialize Grid with top padding ensuring ample clearance below the HUD score bar
    grid = BubbleGrid(
      gameWidth: gameW,
      topPadding: 115.0,
      maxCols: LevelData.standardCols,
    );

    grid.loadLevelGrid(levelData.initialGrid);

    // Initialize background decorative clouds & stars
    _initAtmosphere(gameW, gameH);

    // Render initial grid bubbles
    _renderGridBubbles();

    // Setup cannon
    cannon = CannonComponent(
      position: cannonPos,
      radius: grid.bubbleRadius,
    );
    add(cannon);

    // Setup aim line
    aimLine = AimLineComponent(
      grid: grid,
      gameWidth: gameW,
      gameHeight: gameH,
      cannonPos: cannonPos,
    );
    add(aimLine);

    // Initialize game state
    remainingShots = levelData.maxShots;
    currentBubble = _pickNextColor();
    nextBubble = _pickNextColor();

    _updateReadyBubble();

    // Initial callbacks
    onScoreChanged?.call(score);
    onShotsChanged?.call(remainingShots);
    onNextBubbleChanged?.call(nextBubble);
    onCurrentBubbleChanged?.call(currentBubble);
  }

  void _initAtmosphere(double w, double h) {
    _clouds.clear();
    _clouds.add(_DriftingCloud(x: w * 0.1, y: h * 0.25, width: 90, speed: 8));
    _clouds.add(_DriftingCloud(x: w * 0.7, y: h * 0.45, width: 110, speed: 6));
    _clouds.add(_DriftingCloud(x: w * 0.35, y: h * 0.7, width: 80, speed: 10));

    _twinkles.clear();
    for (int i = 0; i < 22; i++) {
      _twinkles.add(Offset(_random.nextDouble() * w, _random.nextDouble() * h));
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // 1. Whimsical Sky Realm Gradient Background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF2B0938), // Soft magical plum
          Color(0xFF1B0B33), // Dreamy indigo
          Color(0xFF0F172A), // Deep twilight
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Soft Twinkling Background Stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (final pt in _twinkles) {
      canvas.drawCircle(pt, 1.4, starPaint);
    }

    // 3. Drifting Fluffy Whimsical Clouds
    final cloudPaint = Paint()
      ..color = const Color(0xFF6B46C1).withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    for (final cloud in _clouds) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cloud.x, cloud.y),
          width: cloud.width,
          height: cloud.width * 0.45,
        ),
        cloudPaint,
      );
    }

    // 4. Ceiling Anchor Beam (visual separation below top HUD)
    final ceilingY = grid.topPadding;
    final ceilingPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF818CF8), Color(0xFFC084FC), Color(0xFFF472B6)],
      ).createShader(Rect.fromLTWH(0, ceilingY - 4, w, 4))
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, ceilingY - 4, w - 24, 4),
        const Radius.circular(2),
      ),
      ceilingPaint,
    );

    // 5. Danger Line: Cute Candy Striped Boundary Line
    final dangerY = cannonPos.y - grid.bubbleRadius * 2.8;
    final dangerPaint = Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: 0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(10, dangerY), Offset(w - 10, dangerY), dangerPaint);

    super.render(canvas);
  }

  void _renderGridBubbles() {
    for (final b in _gridBubbles.values) {
      b.removeFromParent();
    }
    _gridBubbles.clear();

    for (int r = 0; r < grid.rowCount; r++) {
      final cols = grid.getColsForRow(r);
      for (int c = 0; c < cols; c++) {
        final type = grid.get(r, c);
        if (type != null) {
          final pos = grid.getSlotCenter(r, c);
          final bubble = BubbleComponent(
            type: type,
            radius: grid.bubbleRadius,
            position: pos,
          );
          _gridBubbles[GridSlot(r, c)] = bubble;
          add(bubble);
        }
      }
    }
  }

  BubbleType _pickNextColor() {
    final active = grid.activeColors;
    if (active.isNotEmpty) {
      final list = active.toList();
      return list[_random.nextInt(list.length)];
    }
    final colors = levelData.availableColors;
    return colors[_random.nextInt(colors.length)];
  }

  void _updateReadyBubble() {
    if (readyBubbleComponent != null) {
      readyBubbleComponent!.removeFromParent();
    }
    readyBubbleComponent = BubbleComponent(
      type: currentBubble,
      radius: grid.bubbleRadius,
      position: cannonPos.clone(),
    );
    add(readyBubbleComponent!);
  }

  /// Swap current bubble with next bubble
  void swapBubbles() {
    if (isShooting || isGameOver || isLevelWon) return;
    final temp = currentBubble;
    currentBubble = nextBubble;
    nextBubble = temp;

    _updateReadyBubble();
    readyBubbleComponent?.triggerWobble();

    onNextBubbleChanged?.call(nextBubble);
    onCurrentBubbleChanged?.call(currentBubble);
  }

  /// Equip a special booster into the shooter
  void equipBooster(BubbleType boosterType) {
    if (isShooting || isGameOver || isLevelWon) return;

    currentBubble = boosterType;
    _updateReadyBubble();
    readyBubbleComponent?.triggerWobble();

    // Spawn power-up aura sparks around cannon
    final colorData = BubbleColorData.get(boosterType);
    for (int i = 0; i < 8; i++) {
      add(BubbleSpark(
        position: cannonPos.clone(),
        color: colorData.glowColor,
      ));
    }

    onCurrentBubbleChanged?.call(currentBubble);
  }

  // --- Pan & Touch Aim Controls ---

  @override
  void onPanStart(DragStartInfo info) {
    if (isShooting || isGameOver || isLevelWon) return;
    final pos = info.eventPosition.global;
    if (pos.y < cannonPos.y) {
      aimLine.updateAim(pos, BubbleColorData.get(currentBubble).baseColor, currentBubble);
      cannon.updateAngle(aimLine.aimAngle);
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isShooting || isGameOver || isLevelWon) return;
    final pos = info.eventPosition.global;
    if (pos.y < cannonPos.y) {
      aimLine.updateAim(pos, BubbleColorData.get(currentBubble).baseColor, currentBubble);
      cannon.updateAngle(aimLine.aimAngle);
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (isShooting || isGameOver || isLevelWon) return;
    if (aimLine.isActive) {
      _shoot();
      aimLine.cancelAim();
    }
  }

  @override
  void onPanCancel() {
    aimLine.cancelAim();
  }

  void _shoot() {
    if (isShooting || isGameOver || isLevelWon) return;
    if (remainingShots <= 0) return;

    isShooting = true;
    remainingShots--;
    onShotsChanged?.call(remainingShots);

    // Recoil cannon bounce
    cannon.triggerRecoil();

    readyBubbleComponent?.removeFromParent();
    readyBubbleComponent = null;

    final angle = aimLine.aimAngle;
    const speed = 1550.0;
    final velocity = Vector2(cos(angle), sin(angle)) * speed;

    _activeProjectile = ProjectileBubble(
      type: currentBubble,
      radius: grid.bubbleRadius,
      position: cannonPos.clone(),
      velocity: velocity,
      gameWidth: size.x,
      onHit: _onProjectileHit,
    );
    add(_activeProjectile!);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Drift background clouds
    for (final cloud in _clouds) {
      cloud.x += cloud.speed * dt;
      if (cloud.x - cloud.width / 2 > size.x) {
        cloud.x = -cloud.width / 2;
      }
    }

    if (_activeProjectile != null && !_activeProjectile!.hasHit) {
      if (grid.checkCollision(_activeProjectile!.position, _activeProjectile!.radius)) {
        _activeProjectile!.triggerHit();
      }
    }
  }

  void _onProjectileHit(Vector2 hitPos, BubbleType type) {
    _activeProjectile = null;

    // 1. Snap slot
    final snapSlot = grid.findBestSnapSlot(hitPos);
    grid.set(snapSlot.row, snapSlot.col, type);

    final slotCenter = grid.getSlotCenter(snapSlot.row, snapSlot.col);
    final newBubble = BubbleComponent(
      type: type,
      radius: grid.bubbleRadius,
      position: slotCenter,
    );
    newBubble.triggerWobble();
    _gridBubbles[snapSlot] = newBubble;
    add(newBubble);

    // Wobble neighboring bubbles for jelly impact feedback
    for (final neighbor in grid.getNeighbors(snapSlot.row, snapSlot.col)) {
      _gridBubbles[neighbor]?.triggerWobble();
    }

    // 2. Check cluster match
    final cluster = grid.findMatchingCluster(snapSlot.row, snapSlot.col);

    if (cluster.length >= 3 || type == BubbleType.bomb) {
      combo++;
      onComboChanged?.call(combo);

      final pts = cluster.length * 100 * combo;
      score += pts;
      onScoreChanged?.call(score);

      // Pop cluster bubbles with celebratory sparks
      for (final slot in cluster) {
        grid.remove(slot.row, slot.col);
        final component = _gridBubbles.remove(slot);
        if (component != null) {
          component.startPopAnimation();
          for (int i = 0; i < 7; i++) {
            add(BubbleSpark(
              position: component.position.clone(),
              color: BubbleColorData.get(component.type).baseColor,
            ));
          }
        }
      }

      // Celebratory Kid-Friendly Praise Words!
      String praiseText;
      if (combo >= 4) {
        praiseText = '🌟 UNSTOPPABLE! 🌈';
      } else if (combo >= 3) {
        praiseText = '🎉 INCREDIBLE! +$pts';
      } else if (cluster.length >= 5) {
        praiseText = '🍬 SUPER POP! +$pts';
      } else if (combo == 2) {
        praiseText = '✨ AWESOME! (2X)';
      } else {
        praiseText = '🍭 SWEET! +$pts';
      }

      add(FloatingScoreText(
        position: slotCenter.clone(),
        text: praiseText,
        color: const Color(0xFFFFD54F),
      ));

      // 3. Drop floating orphan bubbles with physics
      final orphans = grid.findFloatingBubbles();
      if (orphans.isNotEmpty) {
        final orphanPts = orphans.length * 150;
        score += orphanPts;
        onScoreChanged?.call(score);

        for (final slot in orphans) {
          final orphanType = grid.get(slot.row, slot.col);
          grid.remove(slot.row, slot.col);
          final component = _gridBubbles.remove(slot);
          component?.removeFromParent();

          if (orphanType != null) {
            final center = grid.getSlotCenter(slot.row, slot.col);
            add(FallingBubble(
              type: orphanType,
              radius: grid.bubbleRadius,
              position: center,
              screenHeight: size.y,
            ));
          }
        }

        add(FloatingScoreText(
          position: Vector2(slotCenter.x, slotCenter.y + 35),
          text: '🎈 +$orphanPts DROP!',
          color: const Color(0xFF67E8F9),
        ));
      }
    } else {
      combo = 0;
      onComboChanged?.call(combo);
    }

    grid.trimEmptyRows();

    // 4. Cycle to next bubble
    currentBubble = nextBubble;
    nextBubble = _pickNextColor();
    _updateReadyBubble();

    onNextBubbleChanged?.call(nextBubble);
    onCurrentBubbleChanged?.call(currentBubble);

    isShooting = false;

    // 5. Check Win / Loss
    _checkGameStatus();
  }

  void _checkGameStatus() {
    if (grid.activeBubbleCount == 0) {
      isLevelWon = true;
      final remainingBonus = remainingShots * 250;
      score += remainingBonus;
      onScoreChanged?.call(score);

      int stars = 1;
      if (score >= levelData.star3Score) {
        stars = 3;
      } else if (score >= levelData.star2Score) {
        stars = 2;
      }

      onLevelComplete?.call(stars, score);
      return;
    }

    if (remainingShots <= 0 && !isShooting) {
      isGameOver = true;
      onLevelFailed?.call('Out of candy shots!');
      return;
    }

    final dangerLineY = cannonPos.y - grid.bubbleRadius * 2.8;
    if (grid.lowestBubbleY >= dangerLineY) {
      isGameOver = true;
      onLevelFailed?.call('Bubbles touched the line!');
      return;
    }
  }

  void restartLevel([LevelData? newLevelData]) {
    if (newLevelData != null) {
      levelData = newLevelData;
    }
    isShooting = false;
    isGameOver = false;
    isLevelWon = false;
    score = 0;
    combo = 0;
    remainingShots = levelData.maxShots;

    grid.loadLevelGrid(levelData.initialGrid);
    _renderGridBubbles();

    currentBubble = _pickNextColor();
    nextBubble = _pickNextColor();
    _updateReadyBubble();

    onScoreChanged?.call(score);
    onShotsChanged?.call(remainingShots);
    onComboChanged?.call(combo);
    onNextBubbleChanged?.call(nextBubble);
    onCurrentBubbleChanged?.call(currentBubble);
  }
}

class _DriftingCloud {
  double x;
  double y;
  final double width;
  final double speed;

  _DriftingCloud({
    required this.x,
    required this.y,
    required this.width,
    required this.speed,
  });
}
