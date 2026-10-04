import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

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
  })  : velocity = Vector2(
          (Random().nextDouble() - 0.5) * 320,
          (Random().nextDouble() - 0.5) * 320,
        ),
        maxLifetime = 0.45 + Random().nextDouble() * 0.35,
        initialRadius = 3.5 + Random().nextDouble() * 4.5,
        shapeType = Random().nextInt(3),
        rotationSpeed = (Random().nextDouble() - 0.5) * 10,
        super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    life += dt;
    if (life >= maxLifetime) {
      removeFromParent();
      return;
    }
    position += velocity * dt;
    velocity.scale(0.91); // soft deceleration
    angle += rotationSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    final progress = (life / maxLifetime).clamp(0.0, 1.0);
    final currentR = initialRadius * (1.0 - progress * 0.7);
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.rotate(angle);

    if (shapeType == 0) {
      // 4-Point Sparkle Star
      final path = Path()
        ..moveTo(0, -currentR * 1.5)
        ..quadraticBezierTo(0, 0, currentR * 1.5, 0)
        ..quadraticBezierTo(0, 0, 0, currentR * 1.5)
        ..quadraticBezierTo(0, 0, -currentR * 1.5, 0)
        ..quadraticBezierTo(0, 0, 0, -currentR * 1.5);
      canvas.drawPath(path, paint);
    } else if (shapeType == 1) {
      // Shiny Circle
      canvas.drawCircle(Offset.zero, currentR, paint);
      final glint = Paint()..color = Colors.white.withValues(alpha: alpha * 0.8);
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

class FloatingScoreText extends PositionComponent {
  final String text;
  final Color color;
  final double maxLifetime = 0.95;
  double life = 0.0;
  final double bounceScale;

  FloatingScoreText({
    required Vector2 position,
    required this.text,
    required this.color,
  })  : bounceScale = 1.0 + Random().nextDouble() * 0.25,
        super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    life += dt;
    if (life >= maxLifetime) {
      removeFromParent();
      return;
    }
    // Float upwards with gentle deceleration
    final speed = max(10.0, 65.0 * (1.0 - life / maxLifetime));
    position.y -= speed * dt;
  }

  @override
  void render(Canvas canvas) {
    final progress = (life / maxLifetime).clamp(0.0, 1.0);
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    // Initial juicy pop scale bounce
    final scale = sin(min(1.0, progress * 4) * pi / 2) * bounceScale;

    canvas.save();
    canvas.scale(scale);

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: color.withValues(alpha: alpha),
        shadows: [
          Shadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.6 * alpha),
            offset: const Offset(2, 3),
          ),
          Shadow(
            blurRadius: 4,
            color: Colors.white.withValues(alpha: 0.8 * alpha),
            offset: const Offset(-1, -1),
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }
}
