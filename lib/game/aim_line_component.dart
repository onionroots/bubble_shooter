import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/bubble_color.dart';
import 'bubble_grid.dart';

class AimLineComponent extends Component {
  final BubbleGrid grid;
  final double gameWidth;
  final double gameHeight;
  final Vector2 cannonPos;

  bool isActive = false;
  double aimAngle = -pi / 2;
  BubbleType bubbleType = BubbleType.red;
  Color aimColor = const Color(0xFFFF2E63);

  // Animated marching flow effect
  double flowOffset = 0.0;
  double pulseTimer = 0.0;

  // Fade in/out when aiming starts/stops
  double _visibility = 0.0;

  // Trajectory (recomputed every frame while aiming)
  final List<Offset> _points = [];
  final List<Offset> _bouncePoints = [];
  Offset? _snapCenter;
  double _totalLength = 0.0;

  /// Simulation step. Must be small (and match the projectile sub-step)
  /// so the prediction lands on exactly the same slot as the real shot.
  static const double _simStep = 4.0;
  static const int _maxBounces = 6;

  AimLineComponent({
    required this.grid,
    required this.gameWidth,
    required this.gameHeight,
    required this.cannonPos,
  });

  void updateAim(Vector2 targetPos, Color color, [BubbleType? type]) {
    aimColor = color;
    if (type != null) bubbleType = type;
    final diff = targetPos - cannonPos;

    // Angle clamp (-165° to -15°)
    double angle = atan2(diff.y, diff.x);
    if (angle > -0.22) angle = -0.22;
    if (angle < -pi + 0.22) angle = -pi + 0.22;

    aimAngle = angle;
    isActive = true;
  }

  void cancelAim() {
    isActive = false;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final target = isActive ? 1.0 : 0.0;
    _visibility += (target - _visibility) * min(1.0, dt * 14.0);
    if ((_visibility - target).abs() < 0.01) _visibility = target;

    if (_visibility <= 0) return;

    flowOffset = (flowOffset + dt * 70.0) % _dotSpacing;
    pulseTimer += dt * 4.0;

    if (isActive) _computeTrajectory();
  }

  void _computeTrajectory() {
    _points.clear();
    _bouncePoints.clear();

    final r = grid.bubbleRadius;
    final pos = cannonPos.clone();
    final dir = Vector2(cos(aimAngle), sin(aimAngle));
    _points.add(Offset(pos.x, pos.y));

    int bounces = 0;
    // Hard cap to avoid infinite loops
    for (int i = 0; i < 2000; i++) {
      pos.add(dir * _simStep);

      // Same wall rules as ProjectileBubble
      if (pos.x - r <= 0) {
        pos.x = r;
        dir.x = -dir.x;
        bounces++;
        _points.add(Offset(pos.x, pos.y));
        _bouncePoints.add(Offset(pos.x, pos.y));
      } else if (pos.x + r >= gameWidth) {
        pos.x = gameWidth - r;
        dir.x = -dir.x;
        bounces++;
        _points.add(Offset(pos.x, pos.y));
        _bouncePoints.add(Offset(pos.x, pos.y));
      }

      // Same hit rule as the real shot (ceiling + bubbles, or ceiling-only for fireball pierce)
      final hit = (bubbleType == BubbleType.fireball)
          ? (pos.y - r <= grid.topPadding)
          : grid.checkCollision(pos, r);
      if (hit || bounces > _maxBounces) break;
    }
    _points.add(Offset(pos.x, pos.y));

    final slot = grid.findBestSnapSlot(pos);
    final c = grid.getSlotCenter(slot.row, slot.col);
    _snapCenter = Offset(c.x, c.y);

    _totalLength = 0;
    for (int i = 0; i < _points.length - 1; i++) {
      _totalLength += (_points[i + 1] - _points[i]).distance;
    }
  }

  static const double _dotSpacing = 20.0;

  @override
  void render(Canvas canvas) {
    if (_visibility <= 0 || _points.length < 2) return;

    final colorData = BubbleColorData.get(bubbleType);
    final v = _visibility;

    _renderBeam(canvas, colorData, v);
    _renderPearlStream(canvas, colorData, v);

    for (int i = 0; i < _bouncePoints.length; i++) {
      _renderBounceRipple(canvas, _bouncePoints[i], colorData, v, i);
    }

    if (_snapCenter != null) {
      _renderTarget(canvas, _snapCenter!, grid.bubbleRadius, colorData, v);
    }
  }

  /// Soft glowing beam underneath the pearls.
  void _renderBeam(Canvas canvas, BubbleColorData colorData, double v) {
    final path = Path()..moveTo(_points.first.dx, _points.first.dy);
    for (int i = 1; i < _points.length; i++) {
      path.lineTo(_points[i].dx, _points[i].dy);
    }

    final start = Offset(cannonPos.x, cannonPos.y);
    final end = _points.last;

    // Outer colored glow that fades toward the target
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = ui.Gradient.linear(start, end, [
          colorData.glowColor.withValues(alpha: 0.0),
          colorData.glowColor.withValues(alpha: 0.35 * v),
          colorData.glowColor.withValues(alpha: 0.12 * v),
        ], [0.0, 0.15, 1.0])
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Thin bright core
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = ui.Gradient.linear(start, end, [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.55 * v),
          Colors.white.withValues(alpha: 0.15 * v),
        ], [0.0, 0.15, 1.0]),
    );
  }

  /// Marching candy pearls that shrink and fade along the path.
  void _renderPearlStream(Canvas canvas, BubbleColorData colorData, double v) {
    final basePaint = Paint();
    final highlightPaint = Paint();
    final shinePaint = Paint();

    double walked = 0.0; // distance walked along whole path
    double next = flowOffset; // next dot distance

    for (int i = 0; i < _points.length - 1; i++) {
      final p1 = _points[i];
      final p2 = _points[i + 1];
      final seg = p2 - p1;
      final segLen = seg.distance;
      if (segLen == 0) continue;
      final segDir = seg / segLen;

      while (next <= walked + segLen) {
        final local = next - walked;
        final pos = p1 + segDir * local;
        final t = (next / _totalLength).clamp(0.0, 1.0);

        // Fade in out of the barrel, fade out toward target
        final fadeIn = (next / 60.0).clamp(0.0, 1.0);
        final fadeOut = 1.0 - 0.6 * t;
        final alpha = (fadeIn * fadeOut * v).clamp(0.0, 1.0);

        if (alpha > 0.02) {
          final wave = 0.6 * sin(pulseTimer * 1.5 - next * 0.08);
          final r = (5.2 - 2.4 * t) + wave;

          basePaint.color = colorData.baseColor.withValues(alpha: alpha);
          highlightPaint.color = colorData.highlightColor.withValues(alpha: alpha * 0.9);
          shinePaint.color = Colors.white.withValues(alpha: alpha * 0.95);

          canvas.drawCircle(pos, r, basePaint);
          canvas.drawCircle(pos + Offset(-r * 0.18, -r * 0.18), r * 0.62, highlightPaint);
          canvas.drawCircle(pos + Offset(-r * 0.35, -r * 0.38), r * 0.28, shinePaint);
        }

        next += _dotSpacing;
      }
      walked += segLen;
    }
  }

  void _renderBounceRipple(
    Canvas canvas,
    Offset pos,
    BubbleColorData colorData,
    double v,
    int index,
  ) {
    // Two staggered expanding rings
    for (int k = 0; k < 2; k++) {
      final phase = ((pulseTimer * 0.35 + k * 0.5 + index * 0.25) % 1.0);
      final ringR = 5 + phase * 14;
      canvas.drawCircle(
        pos,
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * (1 - phase) + 0.4
          ..color = colorData.highlightColor.withValues(alpha: (1 - phase) * 0.8 * v),
      );
    }

    // Glowing core
    canvas.drawCircle(
      pos,
      5,
      Paint()
        ..color = colorData.glowColor.withValues(alpha: 0.7 * v)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 4-point sparkle star
    final s = 6.0 + 1.5 * sin(pulseTimer * 3 + index);
    final w = s * 0.28;
    final star = Path()
      ..moveTo(pos.dx, pos.dy - s)
      ..quadraticBezierTo(pos.dx + w * 0.3, pos.dy - w * 0.3, pos.dx + s, pos.dy)
      ..quadraticBezierTo(pos.dx + w * 0.3, pos.dy + w * 0.3, pos.dx, pos.dy + s)
      ..quadraticBezierTo(pos.dx - w * 0.3, pos.dy + w * 0.3, pos.dx - s, pos.dy)
      ..quadraticBezierTo(pos.dx - w * 0.3, pos.dy - w * 0.3, pos.dx, pos.dy - s)
      ..close();
    canvas.drawPath(star, Paint()..color = Colors.white.withValues(alpha: 0.95 * v));
  }

  void _renderTarget(
    Canvas canvas,
    Offset center,
    double radius,
    BubbleColorData colorData,
    double v,
  ) {
    final pulse = 1.0 + 0.05 * sin(pulseTimer * 2.5);
    final r = radius * pulse;

    // 1. Soft glow under the ghost
    canvas.drawCircle(
      center,
      r * 1.1,
      Paint()
        ..color = colorData.glowColor.withValues(alpha: 0.35 * v)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 2. Translucent glassy ghost body
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            colorData.highlightColor.withValues(alpha: 0.55 * v),
            colorData.baseColor.withValues(alpha: 0.28 * v),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // 3. Rotating dashed reticle ring
    const dashes = 8;
    const sweep = (2 * pi / dashes) * 0.55;
    final rot = pulseTimer * 0.45;
    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.9 * v);
    final ringRect = Rect.fromCircle(center: center, radius: r * 0.98);
    for (int i = 0; i < dashes; i++) {
      canvas.drawArc(ringRect, rot + i * 2 * pi / dashes, sweep, false, dashPaint);
    }

    // 4. Counter-rotating outer brackets
    final outerRect = Rect.fromCircle(center: center, radius: r * 1.32);
    final bracketPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = colorData.glowColor.withValues(alpha: 0.85 * v);
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(outerRect, -rot * 1.4 + i * pi / 2 - 0.3, 0.6, false, bracketPaint);
    }

    // 5. Inner face / special icon
    final innerPaint = Paint()..color = Colors.white.withValues(alpha: 0.85 * v);
    if (colorData.icon != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(colorData.icon!.codePoint),
          style: TextStyle(
            fontSize: radius * 1.0,
            fontFamily: colorData.icon!.fontFamily,
            package: colorData.icon!.fontPackage,
            color: Colors.white.withValues(alpha: 0.9 * v),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
      );
    } else {
      // Kawaii anticipating eyes
      canvas.drawCircle(Offset(center.dx - radius * 0.3, center.dy - radius * 0.1), 3.0, innerPaint);
      canvas.drawCircle(Offset(center.dx + radius * 0.3, center.dy - radius * 0.1), 3.0, innerPaint);

      final mouthPath = Path()
        ..moveTo(center.dx - radius * 0.22, center.dy + radius * 0.22)
        ..quadraticBezierTo(center.dx, center.dy + radius * 0.45, center.dx + radius * 0.22, center.dy + radius * 0.22);
      canvas.drawPath(
        mouthPath,
        Paint()
          ..color = Colors.white.withValues(alpha: v)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}
