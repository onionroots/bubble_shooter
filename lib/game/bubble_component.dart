import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/bubble_color.dart';

class BubbleComponent extends PositionComponent {
  BubbleType type;
  final double radius;
  bool isPopping = false;
  double popProgress = 0.0;

  // Jelly squish and wobble animation
  double wobbleTime = 0.0;
  double wobbleIntensity = 0.0;

  // Eye blinking animation
  double blinkTimer = 0.0;
  double nextBlinkInterval = 3.0;
  bool isBlinking = false;
  double blinkProgress = 0.0;

  // Eye look direction (can slightly look towards aim or center)
  double lookOffsetX = 0.0;
  double lookOffsetY = 0.0;

  // Idle "breathing" + shimmer clock (random phase per bubble)
  double idleTime = 0.0;

  BubbleComponent({
    required this.type,
    required this.radius,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        ) {
    // Stagger blink intervals so all bubbles don't blink in unison
    blinkTimer = Random().nextDouble() * 3.0;
    nextBlinkInterval = 2.5 + Random().nextDouble() * 3.5;
    idleTime = Random().nextDouble() * pi * 2;
  }

  void triggerWobble() {
    wobbleTime = 0.0;
    wobbleIntensity = 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    idleTime += dt;

    if (isPopping) {
      popProgress += dt * 4.8; // pop speed
      if (popProgress >= 1.0) {
        removeFromParent();
      }
      return;
    }

    // Wobble decay
    if (wobbleIntensity > 0) {
      wobbleTime += dt * 18;
      wobbleIntensity = max(0, wobbleIntensity - dt * 2.5);
    }

    // Blinking logic
    blinkTimer += dt;
    if (!isBlinking && blinkTimer >= nextBlinkInterval) {
      isBlinking = true;
      blinkProgress = 0.0;
      blinkTimer = 0.0;
      nextBlinkInterval = 2.5 + Random().nextDouble() * 4.0;
    }

    if (isBlinking) {
      blinkProgress += dt * 8.0; // quick 0.12s blink
      if (blinkProgress >= 1.0) {
        isBlinking = false;
      }
    }
  }

  void startPopAnimation() {
    isPopping = true;
    popProgress = 0.0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);

    // Calculate squash & stretch (with soft idle breathing)
    final breathe = sin(idleTime * 2.2) * 0.018;
    double scaleX = 1.0 + breathe;
    double scaleY = 1.0 - breathe;
    if (wobbleIntensity > 0) {
      final wave = sin(wobbleTime) * wobbleIntensity * 0.18;
      scaleX += wave;
      scaleY -= wave;
    }

    if (isPopping) {
      final popScale = (1.0 + 0.35 * sin(popProgress * pi)) * (1.0 - popProgress);
      scaleX = popScale;
      scaleY = popScale;
    }

    if (scaleX <= 0 || scaleY <= 0) return;

    final colorData = BubbleColorData.get(type);
    final double opacity = isPopping ? (1.0 - popProgress).clamp(0.0, 1.0) : 1.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scaleX, scaleY);

    // 1. Colorful Outer Glow (juicy candy glow)
    double glowStrength = 0.35;
    if (type == BubbleType.bomb || type == BubbleType.rainbow || type == BubbleType.fireball) {
      glowStrength = 0.55 + 0.35 * sin(idleTime * 6);
    }
    final glowPaint = Paint()
      ..color = colorData.glowColor.withValues(alpha: glowStrength * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(Offset.zero, radius * 1.05, glowPaint);

    // 2. Soft Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawCircle(const Offset(0, 2.5), radius * 0.95, shadowPaint);

    // 3. Luscious Candy Sphere Gradient
    final sphereGradient = RadialGradient(
      center: const Alignment(-0.35, -0.42),
      radius: 0.88,
      colors: [
        colorData.highlightColor.withValues(alpha: opacity),
        colorData.baseColor.withValues(alpha: opacity),
        colorData.shadowColor.withValues(alpha: opacity),
      ],
      stops: const [0.0, 0.52, 1.0],
    );

    final sphereRect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final spherePaint = Paint()..shader = sphereGradient.createShader(sphereRect);
    canvas.drawCircle(Offset.zero, radius, spherePaint);

    // 3b. Magical rotating rainbow swirl for the rainbow candy
    if (type == BubbleType.rainbow) {
      final swirl = Paint()
        ..shader = SweepGradient(
          transform: GradientRotation(idleTime * 2.5),
          colors: [
            const Color(0xFFFF2E63),
            const Color(0xFFFF8A00),
            const Color(0xFFFFC300),
            const Color(0xFF10D078),
            const Color(0xFF2292F9),
            const Color(0xFFA259FF),
            const Color(0xFFFF2E63),
          ].map((c) => c.withValues(alpha: 0.85 * opacity)).toList(),
        ).createShader(sphereRect);
      canvas.drawCircle(Offset.zero, radius * 0.97, swirl);
    }

    // 3c. Crisp candy outline for readability against the background
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, radius * 0.06)
      ..color = Color.lerp(colorData.shadowColor, Colors.black, 0.35)!
          .withValues(alpha: 0.75 * opacity);
    canvas.drawCircle(Offset.zero, radius * 0.97, outlinePaint);

    // 4. Glossy Specular Shine (big juicy cartoon glass reflection)
    final shineCenter = Offset(-radius * 0.32, -radius * 0.4);
    final shineRect = Rect.fromCenter(
      center: Offset.zero,
      width: radius * 0.62,
      height: radius * 0.34,
    );
    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.95 * opacity),
          Colors.white.withValues(alpha: 0.15 * opacity),
        ],
      ).createShader(shineRect)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(shineCenter.dx, shineCenter.dy);
    canvas.rotate(-pi / 6);
    canvas.drawOval(shineRect, shinePaint);
    canvas.restore();

    // Secondary tiny sparkle glint
    final smallGlint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65 * opacity);
    canvas.drawCircle(
      Offset(-radius * 0.12, -radius * 0.55),
      radius * 0.08,
      smallGlint,
    );

    // Bottom bounce rim reflection
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.14
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          colorData.highlightColor.withValues(alpha: 0.55 * opacity),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius * 0.92, rimPaint);

    // 5. Special Bomb / Rainbow Icon
    if (colorData.icon != null) {
      _renderSpecialIcon(canvas, colorData, opacity);
    } else {
      // 6. ADORABLE KAWAII FACE (Anime / Pixar style cute eyes & smile!)
      _renderKawaiiFace(canvas, opacity);
    }

    canvas.restore();
  }

  void _renderKawaiiFace(Canvas canvas, double opacity) {
    final eyeSpacing = radius * 0.32;
    final eyeY = radius * 0.05;
    final eyeRadius = radius * 0.16;

    // Blush cheeks
    final blushPaint = Paint()
      ..color = const Color(0xFFFF4081).withValues(alpha: 0.42 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-eyeSpacing * 1.35, eyeY + eyeRadius * 1.3),
        width: eyeRadius * 1.4,
        height: eyeRadius * 0.8,
      ),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(eyeSpacing * 1.35, eyeY + eyeRadius * 1.3),
        width: eyeRadius * 1.4,
        height: eyeRadius * 0.8,
      ),
      blushPaint,
    );

    // Eye blinking height scale
    double eyeScaleY = 1.0;
    if (isBlinking) {
      eyeScaleY = (sin(blinkProgress * pi)).clamp(0.0, 1.0);
      eyeScaleY = 1.0 - eyeScaleY * 0.9; // squash down to thin slit
    }

    // If popping, draw happy squint eyes ("^ ^")
    if (isPopping) {
      final happyEyePaint = Paint()
        ..color = const Color(0xFF1F2937).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = radius * 0.08;

      final leftArc = Path()
        ..addArc(
          Rect.fromCenter(
            center: Offset(-eyeSpacing, eyeY),
            width: eyeRadius * 2,
            height: eyeRadius * 1.8,
          ),
          pi,
          pi,
        );
      final rightArc = Path()
        ..addArc(
          Rect.fromCenter(
            center: Offset(eyeSpacing, eyeY),
            width: eyeRadius * 2,
            height: eyeRadius * 1.8,
          ),
          pi,
          pi,
        );
      canvas.drawPath(leftArc, happyEyePaint);
      canvas.drawPath(rightArc, happyEyePaint);

      // Excited Open Mouth ":D"
      final mouthPaint = Paint()
        ..color = const Color(0xFF1F2937).withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      final mouthPath = Path()
        ..addArc(
          Rect.fromCenter(
            center: Offset(0, eyeY + eyeRadius * 1.2),
            width: eyeRadius * 1.8,
            height: eyeRadius * 1.6,
          ),
          0,
          pi,
        );
      canvas.drawPath(mouthPath, mouthPaint);
      return;
    }

    // Normal Eyes
    for (final x in [-eyeSpacing, eyeSpacing]) {
      final eyeCenter = Offset(x, eyeY);

      canvas.save();
      canvas.translate(eyeCenter.dx, eyeCenter.dy);
      canvas.scale(1.0, eyeScaleY);

      if (eyeScaleY < 0.25) {
        // Closed eyelid slit
        final slitPaint = Paint()
          ..color = const Color(0xFF1F2937).withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = radius * 0.06;
        canvas.drawLine(
          Offset(-eyeRadius, 0),
          Offset(eyeRadius, 0),
          slitPaint,
        );
      } else {
        // Dark Pupil
        final pupilPaint = Paint()
          ..color = const Color(0xFF1F2937).withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset.zero, eyeRadius, pupilPaint);

        // Big Primary Catchlight (Anime white sparkle)
        final catchLightBig = Paint()
          ..color = Colors.white.withValues(alpha: 0.95 * opacity);
        canvas.drawCircle(
          Offset(-eyeRadius * 0.35, -eyeRadius * 0.35),
          eyeRadius * 0.42,
          catchLightBig,
        );

        // Small Secondary Catchlight
        final catchLightSmall = Paint()
          ..color = Colors.white.withValues(alpha: 0.8 * opacity);
        canvas.drawCircle(
          Offset(eyeRadius * 0.35, eyeRadius * 0.35),
          eyeRadius * 0.22,
          catchLightSmall,
        );
      }

      canvas.restore();
    }

    // Cute Tiny Smile Mouth "◡"
    final mouthPaint = Paint()
      ..color = const Color(0xFF1F2937).withValues(alpha: 0.85 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.065;

    final mouthPath = Path()
      ..moveTo(-eyeSpacing * 0.4, eyeY + eyeRadius * 1.35)
      ..quadraticBezierTo(
        0,
        eyeY + eyeRadius * 1.9,
        eyeSpacing * 0.4,
        eyeY + eyeRadius * 1.35,
      );
    canvas.drawPath(mouthPath, mouthPaint);
  }

  void _renderSpecialIcon(Canvas canvas, BubbleColorData colorData, double opacity) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(colorData.icon!.codePoint),
        style: TextStyle(
          fontSize: radius * 1.15,
          fontFamily: colorData.icon!.fontFamily,
          package: colorData.icon!.fontPackage,
          color: Colors.white.withValues(alpha: 0.95 * opacity),
          shadows: [
            Shadow(
              blurRadius: 6,
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(1, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }
}
