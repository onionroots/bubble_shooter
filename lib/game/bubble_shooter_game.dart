import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../models/bubble_color.dart';
import '../models/level_data.dart';
import '../services/progress_service.dart';
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
  final void Function(bool isFever, double progress)? onFeverChanged;

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

  // Floating background clouds, stars & bokeh bubbles
  final List<_DriftingCloud> _clouds = [];
  final List<_Twinkle> _twinkles = [];
  final List<_Bokeh> _bokehs = [];

  // Ambient clock & screen shake
  double _time = 0.0;
  double _shakeTime = 0.0;
  double _shakeIntensity = 0.0;

  // Fever Mode System
  double feverProgress = 0.0;
  bool isFeverMode = false;
  double feverTimer = 0.0;

  BubbleShooterGame({
    required this.levelData,
    this.onScoreChanged,
    this.onShotsChanged,
    this.onComboChanged,
    this.onNextBubbleChanged,
    this.onCurrentBubbleChanged,
    this.onLevelComplete,
    this.onLevelFailed,
    this.onFeverChanged,
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
    _clouds.add(_DriftingCloud(x: w * 0.1, y: h * 0.25, width: 140, speed: 8));
    _clouds.add(_DriftingCloud(x: w * 0.7, y: h * 0.45, width: 170, speed: 6));
    _clouds.add(_DriftingCloud(x: w * 0.35, y: h * 0.7, width: 120, speed: 10));

    _twinkles.clear();
    for (int i = 0; i < 45; i++) {
      _twinkles.add(_Twinkle(
        pos: Offset(_random.nextDouble() * w, _random.nextDouble() * h),
        size: 0.6 + _random.nextDouble() * 1.6,
        phase: _random.nextDouble() * pi * 2,
        speed: 1.0 + _random.nextDouble() * 2.5,
      ));
    }

    _bokehs.clear();
    const palette = [
      Color(0xFFFF66C4),
      Color(0xFF8FD3FE),
      Color(0xFFB87CFF),
      Color(0xFF86F3B8),
      Color(0xFFFFD54F),
    ];
    for (int i = 0; i < 14; i++) {
      _bokehs.add(_Bokeh(
        x: _random.nextDouble() * w,
        y: _random.nextDouble() * h,
        radius: 6 + _random.nextDouble() * 18,
        speed: 8 + _random.nextDouble() * 18,
        sway: _random.nextDouble() * pi * 2,
        color: palette[_random.nextInt(palette.length)],
      ));
    }
  }

  /// Trigger a short camera shake (used for big pops & combos).
  void shake(double intensity) {
    _shakeIntensity = max(_shakeIntensity, intensity);
    _shakeTime = 0.25;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final full = Rect.fromLTWH(0, 0, w, h);

    // 1. Dreamy twilight gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF2A0A4A), // Royal plum
          Color(0xFF1A0B3D), // Dreamy indigo
          Color(0xFF0E1A3F), // Deep ocean twilight
          Color(0xFF0A0F24), // Night floor
        ],
        stops: [0.0, 0.4, 0.75, 1.0],
      ).createShader(full);
    canvas.drawRect(full, bgPaint);

    // 2. Slowly drifting aurora / nebula blobs
    _drawAuroraBlob(
      canvas,
      Offset(w * (0.25 + 0.08 * sin(_time * 0.25)), h * (0.3 + 0.04 * cos(_time * 0.3))),
      w * 0.75,
      const Color(0xFFD946EF),
      0.22,
    );
    _drawAuroraBlob(
      canvas,
      Offset(w * (0.8 + 0.07 * cos(_time * 0.2)), h * (0.55 + 0.05 * sin(_time * 0.27))),
      w * 0.7,
      const Color(0xFF3B82F6),
      0.2,
    );
    _drawAuroraBlob(
      canvas,
      Offset(w * (0.4 + 0.1 * sin(_time * 0.18 + 1)), h * (0.85 + 0.03 * cos(_time * 0.22))),
      w * 0.6,
      const Color(0xFF14B8A6),
      0.14,
    );

    // 3. Twinkling stars with sparkle crosses on bright ones
    final starPaint = Paint();
    for (final s in _twinkles) {
      final tw = 0.5 + 0.5 * sin(_time * s.speed + s.phase);
      starPaint.color = Colors.white.withValues(alpha: 0.15 + 0.6 * tw);
      canvas.drawCircle(s.pos, s.size, starPaint);
      if (s.size > 1.7 && tw > 0.75) {
        final len = s.size * 3.5 * tw;
        final cross = Paint()
          ..color = Colors.white.withValues(alpha: 0.5 * tw)
          ..strokeWidth = 0.8;
        canvas.drawLine(s.pos.translate(-len, 0), s.pos.translate(len, 0), cross);
        canvas.drawLine(s.pos.translate(0, -len), s.pos.translate(0, len), cross);
      }
    }

    // 4. Drifting soft clouds
    final cloudPaint = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    for (final cloud in _clouds) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cloud.x, cloud.y),
          width: cloud.width,
          height: cloud.width * 0.4,
        ),
        cloudPaint,
      );
    }

    // 5. Rising bokeh soap bubbles (background depth)
    for (final b in _bokehs) {
      final bx = b.x + sin(_time * 0.8 + b.sway) * 10;
      final c = Offset(bx, b.y);
      canvas.drawCircle(
        c,
        b.radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              b.color.withValues(alpha: 0.0),
              b.color.withValues(alpha: 0.10),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: b.radius)),
      );
      canvas.drawCircle(
        c,
        b.radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = b.color.withValues(alpha: 0.22),
      );
      canvas.drawCircle(
        c.translate(-b.radius * 0.35, -b.radius * 0.35),
        b.radius * 0.18,
        Paint()..color = Colors.white.withValues(alpha: 0.25),
      );
    }

    // 6. Glowing ceiling beam
    final ceilingY = grid.topPadding;
    final beamRect = Rect.fromLTWH(10, ceilingY - 5, w - 20, 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(beamRect.inflate(3), const Radius.circular(6)),
      Paint()
        ..color = const Color(0xFFC084FC).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(beamRect, const Radius.circular(3)),
      Paint()
        ..shader = LinearGradient(
          colors: const [
            Color(0xFF818CF8),
            Color(0xFFC084FC),
            Color(0xFFF472B6),
            Color(0xFFC084FC),
            Color(0xFF818CF8),
          ],
          transform: GradientRotation(sin(_time * 0.6) * 0.3),
        ).createShader(beamRect),
    );
    canvas.drawLine(
      Offset(16, ceilingY - 4),
      Offset(w - 16, ceilingY - 4),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = 1,
    );

    // 7. Danger zone: animated candy stripe, intensifies as bubbles approach
    final dangerY = cannonPos.y - grid.bubbleRadius * 2.8;
    final span = max(1.0, dangerY - grid.topPadding);
    final closeness = ((grid.lowestBubbleY - grid.topPadding) / span).clamp(0.0, 1.0);
    final danger = pow(closeness, 2).toDouble();
    final dangerPulse = 0.5 + 0.5 * sin(_time * (3 + danger * 6));

    if (danger > 0.3) {
      // Red warning glow rising from the line
      final glowRect = Rect.fromLTWH(0, dangerY - 60, w, 60);
      canvas.drawRect(
        glowRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFFFF1744).withValues(alpha: 0.25 * danger * dangerPulse),
              const Color(0xFFFF1744).withValues(alpha: 0.0),
            ],
          ).createShader(glowRect),
      );
    }

    final dashPaint = Paint()
      ..color = const Color(0xFFFF5277).withValues(alpha: 0.35 + 0.5 * danger * dangerPulse)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const dash = 10.0;
    const gap = 8.0;
    final offset = (_time * 20) % (dash + gap);
    for (double x = 10 - (dash + gap) + offset; x < w - 10; x += dash + gap) {
      final x1 = max(10.0, x);
      final x2 = min(w - 10, x + dash);
      if (x2 > x1) {
        canvas.drawLine(Offset(x1, dangerY), Offset(x2, dangerY), dashPaint);
      }
    }

    // 8. Launch platform glow under the cannon
    final floorRect = Rect.fromCenter(
      center: Offset(cannonPos.x, cannonPos.y + grid.bubbleRadius * 1.6),
      width: w * 0.9,
      height: grid.bubbleRadius * 2.2,
    );
    canvas.drawOval(
      floorRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.35),
            const Color(0xFF8B5CF6).withValues(alpha: 0.0),
          ],
        ).createShader(floorRect),
    );

    // 9. Game components (with screen shake)
    canvas.save();
    if (_shakeTime > 0) {
      final s = _shakeIntensity * (_shakeTime / 0.25);
      canvas.translate(
        (_random.nextDouble() - 0.5) * 2 * s,
        (_random.nextDouble() - 0.5) * 2 * s,
      );
    }
    super.render(canvas);
    canvas.restore();

    // 10. Soft vignette to focus the eye on the play field
    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.45),
          ],
          stops: const [0.6, 1.0],
        ).createShader(full),
    );

    // 11. Fever Mode electrifying rainbow energy border
    if (isFeverMode) {
      final feverPulse = 0.6 + 0.4 * sin(_time * 12.0);
      final borderRect = Rect.fromLTWH(0, 0, w, h);
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..shader = SweepGradient(
          colors: const [
            Color(0xFFFF007F),
            Color(0xFFFFD700),
            Color(0xFF00F5D4),
            Color(0xFF7B2CBF),
            Color(0xFFFF007F),
          ],
          transform: GradientRotation(_time * 4.0),
        ).createShader(borderRect)
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, 4.0 * feverPulse);
      canvas.drawRect(borderRect, borderPaint);
    }
  }

  void _drawAuroraBlob(Canvas canvas, Offset c, double r, Color color, double alpha) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * 0.4),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
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
    cannon.accentColor = BubbleColorData.get(currentBubble).glowColor;
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
      ProgressService.instance.hapticLight();
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
      collides: _checkProjectileCollision,
    );
    add(_activeProjectile!);
  }

  bool _checkProjectileCollision(Vector2 pos, double radius) {
    if (_activeProjectile?.type == BubbleType.fireball) {
      final nearSlots = grid.getOccupiedSlotsNear(pos, radius);
      if (nearSlots.isNotEmpty) {
        _vaporizeFireballSlots(nearSlots, pos);
      }
      return pos.y - radius <= grid.topPadding;
    }
    return grid.checkCollision(pos, radius);
  }

  void _vaporizeFireballSlots(List<GridSlot> slots, Vector2 pos) {
    for (final slot in slots) {
      final comp = _gridBubbles.remove(slot);
      grid.remove(slot.row, slot.col);
      if (comp != null) {
        comp.startPopAnimation();
        add(PopRing(
          position: comp.position.clone(),
          color: const Color(0xFFFF6E40),
          startRadius: grid.bubbleRadius * 1.3,
        ));
        for (int i = 0; i < 7; i++) {
          add(BubbleSpark(
            position: comp.position.clone(),
            color: i.isEven ? const Color(0xFFFF3D00) : const Color(0xFFFFD600),
          ));
        }
      }
    }
    final bonus = slots.length * 150 * (isFeverMode ? 2 : 1);
    score += bonus;
    onScoreChanged?.call(score);
    shake(4.5);
    ProgressService.instance.hapticMedium();
  }

  void _activateFeverMode() {
    isFeverMode = true;
    feverTimer = 8.0;
    feverProgress = 1.0;
    shake(9.0);
    ProgressService.instance.hapticFever();
    ProgressService.instance.unlockAchievement('fever_mode', 'Fever Frenzy!', 'Activated 2X Fever Mode!');
    onFeverChanged?.call(true, 1.0);

    add(FloatingScoreText(
      position: Vector2(size.x / 2, size.y / 2 - 40),
      text: '⚡⚡ FEVER 2X FRENZY! ⚡⚡',
      color: const Color(0xFFFFD700),
    ));
  }

  double _lastReportedFever = -1.0;
  bool _lastReportedFeverMode = false;

  void _notifyFeverIfChanged(bool active, double prog) {
    if (_lastReportedFeverMode != active || (_lastReportedFever - prog).abs() >= 0.02) {
      _lastReportedFeverMode = active;
      _lastReportedFever = prog;
      onFeverChanged?.call(active, prog);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    if (_shakeTime > 0) {
      _shakeTime = max(0, _shakeTime - dt);
      if (_shakeTime == 0) _shakeIntensity = 0;
    }

    // Fever Mode countdown and decay
    if (isFeverMode) {
      feverTimer -= dt;
      feverProgress = (feverTimer / 8.0).clamp(0.0, 1.0);
      if (feverTimer <= 0) {
        isFeverMode = false;
        feverProgress = 0.0;
        _lastReportedFeverMode = false;
        _lastReportedFever = 0.0;
        onFeverChanged?.call(false, 0.0);
        add(FloatingScoreText(
          position: cannonPos.clone() - Vector2(0, 100),
          text: 'FEVER COOLDOWN',
          color: const Color(0xFFC4B5FD),
        ));
      } else {
        _notifyFeverIfChanged(true, feverProgress);
      }
    } else if (feverProgress > 0) {
      feverProgress = max(0.0, feverProgress - dt * 0.02);
      _notifyFeverIfChanged(false, feverProgress);
    }

    // Drift background clouds
    for (final cloud in _clouds) {
      cloud.x += cloud.speed * dt;
      if (cloud.x - cloud.width / 2 > size.x) {
        cloud.x = -cloud.width / 2;
      }
    }

    // Rise bokeh bubbles
    for (final b in _bokehs) {
      b.y -= b.speed * dt;
      if (b.y + b.radius < 0) {
        b.y = size.y + b.radius;
        b.x = _random.nextDouble() * size.x;
      }
    }

    if (_activeProjectile != null && !_activeProjectile!.hasHit) {
      if (_checkProjectileCollision(_activeProjectile!.position, _activeProjectile!.radius)) {
        _activeProjectile!.triggerHit();
      }
    }
  }

  void _onProjectileHit(Vector2 hitPos, BubbleType type) {
    _activeProjectile = null;

    if (type == BubbleType.fireball) {
      // Fireball scorched through! Drop any remaining orphan bubbles
      final orphans = grid.findFloatingBubbles();
      if (orphans.isNotEmpty) {
        _dropOrphans(orphans, Vector2(hitPos.x, grid.topPadding + 40));
      }
      grid.trimEmptyRows();
      currentBubble = nextBubble;
      nextBubble = _pickNextColor();
      _updateReadyBubble();
      onNextBubbleChanged?.call(nextBubble);
      onCurrentBubbleChanged?.call(currentBubble);
      isShooting = false;
      _checkGameStatus();
      return;
    }

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

      // Boost Fever meter
      feverProgress = (feverProgress + 0.22 + (combo * 0.06)).clamp(0.0, 1.0);
      if (feverProgress >= 1.0 && !isFeverMode) {
        _activateFeverMode();
      } else {
        onFeverChanged?.call(isFeverMode, feverProgress);
      }

      final feverMult = isFeverMode ? 2 : 1;
      final pts = cluster.length * 100 * combo * feverMult;
      score += pts;
      onScoreChanged?.call(score);
      ProgressService.instance.hapticMedium();

      if (combo >= 4) {
        ProgressService.instance.unlockAchievement('combo_master', 'Combo Master!', 'Reached a 4X combo streak!');
      }

      // Pop cluster bubbles with celebratory sparks
      for (final slot in cluster) {
        grid.remove(slot.row, slot.col);
        final component = _gridBubbles.remove(slot);
        if (component != null) {
          component.startPopAnimation();
          final colorData = BubbleColorData.get(component.type);
          add(PopRing(
            position: component.position.clone(),
            color: colorData.glowColor,
            startRadius: grid.bubbleRadius,
          ));
          for (int i = 0; i < 9; i++) {
            add(BubbleSpark(
              position: component.position.clone(),
              color: i.isEven ? colorData.baseColor : colorData.highlightColor,
            ));
          }
        }
      }

      // Juicy camera shake scaled to the size of the pop
      shake(min(9.0, 1.5 + cluster.length * 0.6 + combo * 0.8));

      // Celebratory Kid-Friendly Praise Words!
      String praiseText;
      if (isFeverMode) {
        praiseText = '⚡ FEVER 2X! +$pts ⚡';
      } else if (combo >= 4) {
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
        color: isFeverMode ? const Color(0xFFFFD700) : const Color(0xFFFFD54F),
      ));

      // 3. Drop floating orphan bubbles with physics
      final orphans = grid.findFloatingBubbles();
      if (orphans.isNotEmpty) {
        _dropOrphans(orphans, slotCenter);
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

  void _dropOrphans(List<GridSlot> orphans, [Vector2? fallbackPos]) {
    final feverMult = isFeverMode ? 2 : 1;
    final orphanPts = orphans.length * 150 * feverMult;
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

    final pos = fallbackPos ?? (orphans.isNotEmpty ? grid.getSlotCenter(orphans.first.row, orphans.first.col) : cannonPos);
    add(FloatingScoreText(
      position: Vector2(pos.x, pos.y + 35),
      text: '🎈 +$orphanPts DROP!',
      color: const Color(0xFF67E8F9),
    ));
    ProgressService.instance.hapticMedium();
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

      ProgressService.instance.hapticSuccess();
      ProgressService.instance.unlockAchievement('first_win', 'Level Cleared!', 'Completed a level successfully');
      if (remainingShots >= 5) {
        ProgressService.instance.unlockAchievement('sharpshooter', 'Sharpshooter!', 'Cleared with 5+ shots remaining');
      }

      onLevelComplete?.call(stars, score);
      return;
    }

    if (remainingShots <= 0 && !isShooting) {
      isGameOver = true;
      ProgressService.instance.hapticHeavy();
      onLevelFailed?.call('Out of candy shots!');
      return;
    }

    final dangerLineY = cannonPos.y - grid.bubbleRadius * 2.8;
    if (grid.lowestBubbleY >= dangerLineY) {
      isGameOver = true;
      ProgressService.instance.hapticHeavy();
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

class _Twinkle {
  final Offset pos;
  final double size;
  final double phase;
  final double speed;

  _Twinkle({
    required this.pos,
    required this.size,
    required this.phase,
    required this.speed,
  });
}

class _Bokeh {
  double x;
  double y;
  final double radius;
  final double speed;
  final double sway;
  final Color color;

  _Bokeh({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.sway,
    required this.color,
  });
}
