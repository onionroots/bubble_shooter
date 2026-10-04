import 'package:flame/components.dart';
import '../models/bubble_color.dart';
import 'bubble_component.dart';
import 'particle_effects.dart';

class ProjectileBubble extends BubbleComponent {
  final Vector2 velocity;
  final double gameWidth;
  final void Function(Vector2 finalPosition, BubbleType type) onHit;

  /// Collision test against the grid, evaluated on every sub-step.
  final bool Function(Vector2 pos, double radius)? collides;

  /// Must match AimLineComponent's simulation step for accurate prediction.
  static const double subStep = 4.0;

  ProjectileBubble({
    required super.type,
    required super.radius,
    required super.position,
    required this.velocity,
    required this.gameWidth,
    required this.onHit,
    this.collides,
  });

  bool hasHit = false;
  double _trailTimer = 0.0;
  double _pendingDistance = 0.0;

  @override
  void update(double dt) {
    if (hasHit) return;

    super.update(dt);

    final glow = BubbleColorData.get(type).glowColor;

    // Comet trail
    _trailTimer += dt;
    while (_trailTimer >= 0.012) {
      _trailTimer -= 0.012;
      parent?.add(TrailParticle(
        position: position.clone(),
        color: glow,
        startRadius: radius * 0.95,
      ));
    }

    // Move in exact fixed-length steps (same as the aim line simulation)
    _pendingDistance += velocity.length * dt;
    int guard = 400;
    while (_pendingDistance >= subStep && guard-- > 0) {
      _pendingDistance -= subStep;
      final stepVel = velocity.normalized() * subStep;
      position += stepVel;

      // Bounce off left wall
      if (position.x - radius <= 0) {
        position.x = radius;
        velocity.x = -velocity.x;
        parent?.add(PopRing(position: position.clone(), color: glow, startRadius: radius * 0.6));
      }
      // Bounce off right wall
      else if (position.x + radius >= gameWidth) {
        position.x = gameWidth - radius;
        velocity.x = -velocity.x;
        parent?.add(PopRing(position: position.clone(), color: glow, startRadius: radius * 0.6));
      }

      if (collides != null && collides!(position, radius)) {
        triggerHit();
        return;
      }
    }
  }

  void triggerHit() {
    if (hasHit) return;
    hasHit = true;
    onHit(position.clone(), type);
    removeFromParent();
  }
}
