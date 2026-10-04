import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CannonComponent extends PositionComponent {
  final double radius;
  double aimAngle = -pi / 2;

  /// Glow color matching the currently loaded bubble.
  Color accentColor = const Color(0xFFFFD54F);

  // Recoil kickback animation
  double recoilProgress = 1.0;

  // Ambient animation clock
  double _time = 0.0;

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
    _time += dt;
    if (recoilProgress < 1.0) {
      recoilProgress = min(1.0, recoilProgress + dt * 6.0); // snappy recoil bounce
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    // Calculate recoil displacement
    double recoilOffset = 0.0;
    if (recoilProgress < 1.0) {
      recoilOffset = sin(recoilProgress * pi) * radius * 0.35;
    }

    final pulse = 0.5 + 0.5 * sin(_time * 3.0);

    // 0. Soft accent aura on the floor (pulses with current bubble color)
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.45 + 0.2 * pulse),
          accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 2.6));
    canvas.drawCircle(center, radius * 2.6, auraPaint);

    // 1. Glossy candy pedestal base
    final baseR = radius * 1.4;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center.translate(0, 4), baseR, shadowPaint);

    final pedestalPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.4),
        colors: [Color(0xFF7C3AED), Color(0xFF4C1D95), Color(0xFF2E1065)],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseR));
    canvas.drawCircle(center, baseR, pedestalPaint);

    // Golden rim
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFFF59D),
          Color(0xFFFFB300),
          Color(0xFFFFF59D),
          Color(0xFFFF8F00),
          Color(0xFFFFF59D),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: baseR));
    canvas.drawCircle(center, baseR, rimPaint);

    // Inner accent ring
    final innerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = accentColor.withValues(alpha: 0.55 + 0.35 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    canvas.drawCircle(center, radius * 1.12, innerRing);

    // Orbiting lights around the base
    const lights = 10;
    for (int i = 0; i < lights; i++) {
      final a = i * (2 * pi / lights) + _time * 0.8;
      final p = Offset(
        center.dx + cos(a) * radius * 1.26,
        center.dy + sin(a) * radius * 1.26,
      );
      final twinkle = 0.5 + 0.5 * sin(_time * 4 + i);
      canvas.drawCircle(
        p,
        3.2,
        Paint()
          ..color = accentColor.withValues(alpha: 0.4 * twinkle)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
      canvas.drawCircle(
        p,
        1.6,
        Paint()..color = Colors.white.withValues(alpha: 0.6 + 0.4 * twinkle),
      );
    }

    // 2. Rotating Toy Nozzle with Recoil
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(aimAngle + pi / 2); // 0 points upwards
    canvas.translate(0, recoilOffset); // kickback on shoot

    final barrelRect = Rect.fromCenter(
      center: Offset(0, -radius * 0.7),
      width: radius * 1.0,
      height: radius * 1.5,
    );

    final barrelPath = Path()
      ..moveTo(-radius * 0.5, 0)
      ..lineTo(-radius * 0.38, -radius * 1.38)
      ..lineTo(radius * 0.38, -radius * 1.38)
      ..lineTo(radius * 0.5, 0)
      ..close();

    // Barrel shadow
    canvas.drawPath(
      barrelPath.shift(const Offset(0, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Barrel body: horizontal gradient for a cylindrical look
    final barrelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFC2185B),
          Color(0xFFFF4081),
          Color(0xFFFF80AB),
          Color(0xFFE91E63),
          Color(0xFF880E4F),
        ],
        stops: [0.0, 0.3, 0.45, 0.7, 1.0],
      ).createShader(barrelRect);
    canvas.drawPath(barrelPath, barrelPaint);

    // Candy swirl stripes on barrel (clipped to barrel)
    canvas.save();
    canvas.clipPath(barrelPath);
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = radius * 0.16
      ..style = PaintingStyle.stroke;
    for (double y = 0.2; y < 1.6; y += 0.42) {
      canvas.drawLine(
        Offset(-radius * 0.6, -radius * y),
        Offset(radius * 0.6, -radius * (y + 0.3)),
        stripePaint,
      );
    }
    canvas.restore();

    // Barrel outline
    canvas.drawPath(
      barrelPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF4A0E2E).withValues(alpha: 0.6),
    );

    // Golden muzzle crown ring
    final muzzleRect = Rect.fromCenter(
      center: Offset(0, -radius * 1.38),
      width: radius * 0.92,
      height: radius * 0.38,
    );
    canvas.drawOval(
      muzzleRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFFFF59D), Color(0xFFFF8F00)],
        ).createShader(muzzleRect),
    );

    // Muzzle opening glowing with the loaded bubble's color
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -radius * 1.38),
        width: radius * 0.62,
        height: radius * 0.2,
      ),
      Paint()
        ..color = accentColor.withValues(alpha: 0.7 + 0.3 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2),
    );

    canvas.restore();
  }
}
