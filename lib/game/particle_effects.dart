import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

final Random _rng = Random();

class BubbleSpark extends PositionComponent {
  final Color color;
  final Vector2 velocity;
  final double maxLifetime;
  double life = 0.0;
  final double initialRadius;
  final int shapeType; // 0: star/diamond, 1: circle, 2: candy heart
  final double rotationSpeed;

  BubbleSpark({
    required Vector2 position,
    required this.color,
  })  : velocity = _randomVelocity(),
        maxLifetime = 0.5 + _rng.nextDouble() * 0.4,
        initialRadius = 3.0 + _rng.nextDouble() * 4.5,
        shapeType = _rng.nextInt(3),
        rotationSpeed = (_rng.nextDouble() - 0.5) * 12,
        super(position: position, priority: 20);

  static Vector2 _randomVelocity() {
    final a = _rng.nextDouble() * pi * 2;
    final s = 120 + _rng.nextDouble() * 260;
    return Vector2(cos(a) * s, sin(a) * s);
  }

  @override
  void update(double dt) {
    super.update(dt);
    life += dt;
    if (life >= maxLifetime) {
      removeFromParent();
      return;
    }
    position += velocity * dt;
    velocity.scale(0.92); // soft deceleration
    velocity.y += 380 * dt; // light gravity so sparks gently fall
    angle += rotationSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    final progress = (life / maxLifetime).clamp(0.0, 1.0);
    final currentR = initialRadius * (1.0 - progress * 0.7);
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    // Soft additive-looking glow halo
    final glow = Paint()
      ..color = color.withValues(alpha: alpha * 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset.zero, currentR * 1.8, glow);

    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.rotate(angle);

    if (shapeType == 0) {
      // 4-Point Sparkle Star
      final path = Path()
        ..moveTo(0, -currentR * 1.6)
        ..quadraticBezierTo(0, 0, currentR * 1.6, 0)
        ..quadraticBezierTo(0, 0, 0, currentR * 1.6)
        ..quadraticBezierTo(0, 0, -currentR * 1.6, 0)
        ..quadraticBezierTo(0, 0, 0, -currentR * 1.6);
      canvas.drawPath(path, paint);
      canvas.drawCircle(
        Offset.zero,
        currentR * 0.35,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    } else if (shapeType == 1) {
      // Shiny Circle
      canvas.drawCircle(Offset.zero, currentR, paint);
      final glint = Paint()..color = Colors.white.withValues(alpha: alpha * 0.85);
      canvas.drawCircle(Offset(-currentR * 0.3, -currentR * 0.3), currentR * 0.35, glint);
    } else {
      // Candy Diamond
      final path = Path()
        ..moveTo(0, -currentR * 1.2)
        ..lineTo(currentR * 1.2, 0)
        ..lineTo(0, currentR * 1.2)
        ..lineTo(-currentR * 1.2, 0)
        ..close();
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }
}

/// Expanding shockwave ring drawn when a bubble pops.
class PopRing extends PositionComponent {
  final Color color;
  final double startRadius;
  final double maxLifetime;
  double life = 0.0;

  PopRing({
    required Vector2 position,
    required this.color,
    required this.startRadius,
    this.maxLifetime = 0.38,
  }) : super(position: position, priority: 15);

  @override
  void update(double dt) {
    super.update(dt);
    life += dt;
    if (life >= maxLifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (life / maxLifetime).clamp(0.0, 1.0);
    final eased = 1 - pow(1 - t, 3).toDouble();
    final r = startRadius * (0.8 + eased * 1.1);
    final alpha = (1.0 - t);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * (1 - t) + 0.5
      ..color = color.withValues(alpha: alpha * 0.9);
    canvas.drawCircle(Offset.zero, r, ring);

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: alpha * 0.7);
    canvas.drawCircle(Offset.zero, r * 0.82, inner);

    // Flash fill at the very beginning
    if (t < 0.35) {
      final flash = Paint()
        ..color = Colors.white.withValues(alpha: (0.35 - t) * 1.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset.zero, startRadius * 0.9, flash);
    }
  }
}

/// Fading glowing dot left behind a flying projectile (comet trail).
class TrailParticle extends PositionComponent {
  final Color color;
  final double startRadius;
  final double maxLifetime;
  double life = 0.0;

  TrailParticle({
    required Vector2 position,
    required this.color,
    required this.startRadius,
    this.maxLifetime = 0.28,
  }) : super(position: position, priority: -1);

  @override
  void update(double dt) {
    super.update(dt);
    life += dt;
    if (life >= maxLifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (life / maxLifetime).clamp(0.0, 1.0);
    final r = startRadius * (1 - t * 0.85);
    final paint = Paint()
      ..color = color.withValues(alpha: (1 - t) * 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset.zero, r, paint);
    canvas.drawCircle(
      Offset.zero,
      r * 0.35,
      Paint()..color = Colors.white.withValues(alpha: (1 - t) * 0.55),
    );
  }
}

class FloatingScoreText extends PositionComponent {
  final String text;
  final Color color;
  final double maxLifetime = 1.1;
  double life = 0.0;
  final double bounceScale;

  FloatingScoreText({
    required Vector2 position,
    required this.text,
    required this.color,
  })  : bounceScale = 1.0 + _rng.nextDouble() * 0.2,
        super(position: position, priority: 30);

  @override
  void update(double dt) {
    super.update(dt);
    life += dt;
    if (life >= maxLifetime) {
      removeFromParent();
      return;
    }
    // Float upwards with gentle deceleration
    final speed = max(10.0, 70.0 * (1.0 - life / maxLifetime));
    position.y -= speed * dt;
  }

  @override
  void render(Canvas canvas) {
    final progress = (life / maxLifetime).clamp(0.0, 1.0);
    // Stay fully visible for the first half, then fade
    final alpha = progress < 0.5 ? 1.0 : (1.0 - (progress - 0.5) * 2).clamp(0.0, 1.0);

    // Elastic pop-in scale
    final p = min(1.0, progress * 5);
    final elastic = 1 + sin(p * pi) * 0.25;
    final scale = p * elastic * bounceScale;
    if (scale <= 0) return;

    canvas.save();
    canvas.scale(scale);

    const fontSize = 22.0;

    // Thick dark outline
    final outline = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xFF2A0845).withValues(alpha: alpha),
          shadows: [
            Shadow(
              blurRadius: 10,
              color: color.withValues(alpha: 0.7 * alpha),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final origin = Offset(-outline.width / 2, -outline.height / 2);
    outline.paint(canvas, origin);

    // Gradient fill
    final fill = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          foreground: Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: alpha),
                color.withValues(alpha: alpha),
              ],
            ).createShader(Rect.fromLTWH(
              origin.dx,
              origin.dy,
              outline.width,
              outline.height,
            )),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    fill.paint(canvas, origin);

    canvas.restore();
  }
}
