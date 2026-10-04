import 'package:flame/components.dart';
import '../models/bubble_color.dart';
import 'bubble_component.dart';

class ProjectileBubble extends BubbleComponent {
  final Vector2 velocity;
  final double gameWidth;
  final void Function(Vector2 finalPosition, BubbleType type) onHit;

  ProjectileBubble({
    required super.type,
    required super.radius,
    required super.position,
    required this.velocity,
    required this.gameWidth,
    required this.onHit,
  });

  bool hasHit = false;

  @override
  void update(double dt) {
    if (hasHit) return;

    super.update(dt);

    position += velocity * dt;

    // Bounce off left wall
    if (position.x - radius <= 0) {
      position.x = radius;
      velocity.x = -velocity.x;
    }
    // Bounce off right wall
    else if (position.x + radius >= gameWidth) {
      position.x = gameWidth - radius;
      velocity.x = -velocity.x;
    }
  }

  void triggerHit() {
    if (hasHit) return;
    hasHit = true;
    onHit(position.clone(), type);
    removeFromParent();
  }
}
