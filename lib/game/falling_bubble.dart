import 'dart:math';
import 'package:flame/components.dart';
import 'bubble_component.dart';

class FallingBubble extends BubbleComponent {
  final double screenHeight;
  final Vector2 velocity;
  final double spinSpeed;

  FallingBubble({
    required super.type,
    required super.radius,
    required super.position,
    required this.screenHeight,
  })  : velocity = Vector2(
          (Random().nextDouble() - 0.5) * 140,
          -60 - Random().nextDouble() * 80, // slight upward hop first
        ),
        spinSpeed = (Random().nextDouble() - 0.5) * 6;

  @override
  void update(double dt) {
    super.update(dt);

    // Gravity
    velocity.y += 1100 * dt;
    position += velocity * dt;
    angle += spinSpeed * dt;

    if (position.y > screenHeight + 50) {
      removeFromParent();
    }
  }
}
