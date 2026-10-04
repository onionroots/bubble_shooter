import 'dart:math';
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
    if (isActive) {
      // Marching candy pearls flow toward target
      flowOffset = (flowOffset + dt * 60.0) % 24.0;
      pulseTimer += dt * 4.0;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isActive) return;

    final bubbleR = grid.bubbleRadius;
    final minX = bubbleR;
    final maxX = gameWidth - bubbleR;
    final topY = grid.topPadding + bubbleR;

    Vector2 currentPos = cannonPos.clone();
    Vector2 dir = Vector2(cos(aimAngle), sin(aimAngle)).normalized();

    final points = <Offset>[Offset(currentPos.x, currentPos.y)];
    final bouncePoints = <Offset>[];

    const double stepSize = 12.0;
    bool hitObstacle = false;
    int maxSteps = 140;

    while (!hitObstacle && maxSteps > 0) {
      maxSteps--;
      currentPos += dir * stepSize;

      // Wall bounce left
      if (currentPos.x <= minX) {
        currentPos.x = minX;
        dir.x = -dir.x;
        final bouncePt = Offset(currentPos.x, currentPos.y);
        points.add(bouncePt);
        bouncePoints.add(bouncePt);
      }
      // Wall bounce right
      else if (currentPos.x >= maxX) {
        currentPos.x = maxX;
        dir.x = -dir.x;
        final bouncePt = Offset(currentPos.x, currentPos.y);
        points.add(bouncePt);
        bouncePoints.add(bouncePt);
      }

      // Ceiling hit
      if (currentPos.y <= topY) {
        currentPos.y = topY;
        points.add(Offset(currentPos.x, currentPos.y));
        hitObstacle = true;
        break;
      }

      // Bubble hit check
      if (grid.checkCollision(currentPos, bubbleR)) {
        points.add(Offset(currentPos.x, currentPos.y));
        hitObstacle = true;
        break;
      }
    }

    if (points.length < 2) return;

    final colorData = BubbleColorData.get(bubbleType);

    // 1. Render wall bounce sparkles
    for (final bPt in bouncePoints) {
      _renderBounceRipple(canvas, bPt, colorData.highlightColor);
    }

    // 2. Render marching glowing candy pearls along trajectory
    _renderCandyStream(canvas, points, colorData);

    // 3. Render Ghost Snap Preview Bubble at destination!
    final lastPoint = points.last;
    final snapSlot = grid.findBestSnapSlot(Vector2(lastPoint.dx, lastPoint.dy));
    final snapCenter = grid.getSlotCenter(snapSlot.row, snapSlot.col);

    _renderGhostTargetBubble(
      canvas,
      Offset(snapCenter.x, snapCenter.y),
      bubbleR,
      colorData,
    );
  }

  void _renderCandyStream(
    Canvas canvas,
    List<Offset> points,
    BubbleColorData colorData,
  ) {
    const double dotSpacing = 22.0;
    double currentDistance = flowOffset;

    // Outer glow paint
    final glowPaint = Paint()
      ..color = colorData.glowColor.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    // Core pearl paint
    final pearlPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        colors: [
          colorData.highlightColor,
          colorData.baseColor,
        ],
      ).createShader(const Rect.fromLTWH(-6, -6, 12, 12))
      ..style = PaintingStyle.fill;

    // Specular shine glint
    final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.9);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final segLength = (p2 - p1).distance;
      final segDir = (p2 - p1) / (segLength == 0 ? 1 : segLength);

      while (currentDistance < segLength) {
        final pos = p1 + segDir * currentDistance;

        // Size pulses gently along flow
        final pulse = 4.2 + 0.8 * sin(pulseTimer + currentDistance * 0.1);

        // Draw soft glow
        canvas.drawCircle(pos, pulse * 1.5, glowPaint);

        // Draw core pearl
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.drawCircle(Offset.zero, pulse, pearlPaint);
        // Draw glint
        canvas.drawCircle(Offset(-pulse * 0.35, -pulse * 0.35), pulse * 0.35, shinePaint);
        canvas.restore();

        currentDistance += dotSpacing;
      }
      currentDistance -= segLength;
    }
  }

  void _renderBounceRipple(Canvas canvas, Offset pos, Color color) {
    final ripplePulse = 1.0 + 0.3 * sin(pulseTimer * 2);
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(pos, 9.0 * ripplePulse, ringPaint);

    // Sparkle star cross
    final starPaint = Paint()..color = Colors.white;
    canvas.drawLine(Offset(pos.dx - 5, pos.dy), Offset(pos.dx + 5, pos.dy), starPaint);
    canvas.drawLine(Offset(pos.dx, pos.dy - 5), Offset(pos.dx, pos.dy + 5), starPaint);
  }

  void _renderGhostTargetBubble(
    Canvas canvas,
    Offset center,
    double radius,
    BubbleColorData colorData,
  ) {
    final pulseScale = 1.0 + 0.06 * sin(pulseTimer * 2.5);
    final currentR = radius * pulseScale;

    // 1. Ghost Translucent Body
    final ghostFill = Paint()
      ..color = colorData.baseColor.withValues(alpha: 0.32)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, currentR, ghostFill);

    // 2. Dashed / Glowing Animated Ring
    final ghostBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);
    canvas.drawCircle(center, currentR * 0.95, ghostBorder);

    // 3. Inner Kawaii Anticipation Smiley Face or Star icon
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    if (colorData.icon != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(colorData.icon!.codePoint),
          style: TextStyle(
            fontSize: radius * 1.1,
            fontFamily: colorData.icon!.fontFamily,
            package: colorData.icon!.fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
      );
    } else {
      // Kawaii anticipating wink eyes at target slot
      canvas.drawCircle(Offset(center.dx - radius * 0.3, center.dy - radius * 0.1), 3.0, innerPaint);
      canvas.drawCircle(Offset(center.dx + radius * 0.3, center.dy - radius * 0.1), 3.0, innerPaint);

      // Sweet anticipation mouth
      final mouthPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final mouthPath = Path()
        ..moveTo(center.dx - radius * 0.22, center.dy + radius * 0.22)
        ..quadraticBezierTo(center.dx, center.dy + radius * 0.45, center.dx + radius * 0.22, center.dy + radius * 0.22);
      canvas.drawPath(mouthPath, mouthPaint);
    }

    // 4. Subtle Outer Pulse Aura
    final auraPaint = Paint()
      ..color = colorData.glowColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, currentR * 1.18, auraPaint);
  }
}
