import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CannonComponent extends PositionComponent {
  final double radius;
  double aimAngle = -pi / 2;

  // Recoil kickback animation
  double recoilProgress = 1.0;

  CannonComponent({
    required Vector2 position,
    required this.radius,
  }) : super(
          position: position,
          size: Vector2.all(radius * 3.4),
          anchor: Anchor.center,
        );

  void updateAngle(double angle) {
    aimAngle = angle;
  }

  void triggerRecoil() {
    recoilProgress = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (recoilProgress < 1.0) {
      recoilProgress += dt * 6.0; // snappy recoil bounce
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    // Calculate recoil displacement
    double recoilOffset = 0.0;
    if (recoilProgress < 1.0) {
      recoilProgress.clamp(0.0, 1.0);
      recoilOffset = sin(recoilProgress * pi) * radius * 0.35;
    }

    // 1. Cute Wooden / Candy Pedestal Base
    final pedestalPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFB300), Color(0xFFFF8F00), Color(0xFFE65100)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.45));

    final pedestalBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = const Color(0xFFFFF176);

    canvas.drawCircle(center, radius * 1.4, pedestalPaint);
    canvas.drawCircle(center, radius * 1.4, pedestalBorder);

    // Decorative golden rivets around base
    final rivetPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 8; i++) {
      final a = i * (2 * pi / 8);
      final rx = center.dx + cos(a) * radius * 1.25;
      final ry = center.dy + sin(a) * radius * 1.25;
      canvas.drawCircle(Offset(rx, ry), 2.2, rivetPaint);
    }

    // 2. Rotating Toy Nozzle with Recoil
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(aimAngle + pi / 2); // 0 points upwards
    canvas.translate(0, recoilOffset); // kickback on shoot

    // Barrel body (warm candy / wooden texture)
    final barrelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF7043), Color(0xFFD84315)],
      ).createShader(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 1.3,
          height: radius * 2.3,
        ),
      );

    final barrelPath = Path()
      ..moveTo(-radius * 0.48, 0)
      ..lineTo(-radius * 0.36, -radius * 1.35)
      ..lineTo(radius * 0.36, -radius * 1.35)
      ..lineTo(radius * 0.48, 0)
      ..close();

    canvas.drawPath(barrelPath, barrelPaint);

    // Candy swirl stripes on barrel
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(-radius * 0.4, -radius * 0.4),
      Offset(radius * 0.4, -radius * 0.7),
      stripePaint,
    );
    canvas.drawLine(
      Offset(-radius * 0.36, -radius * 0.9),
      Offset(radius * 0.36, -radius * 1.15),
      stripePaint,
    );

    // Golden muzzle crown ring
    final muzzleRing = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -radius * 1.35),
        width: radius * 0.8,
        height: radius * 0.35,
      ),
      muzzleRing,
    );

    // Shiny muzzle highlight
    final muzzleHighlight = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -radius * 1.35),
        width: radius * 0.65,
        height: radius * 0.22,
      ),
      muzzleHighlight,
    );

    canvas.restore();
  }
}
