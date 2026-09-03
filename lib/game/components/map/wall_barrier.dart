import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

// Um bloco invisível (ou sólido) grande apenas para a física da parede
class WallBarrier extends PositionComponent with CollisionCallbacks {
  WallBarrier({required Vector2 position, required Vector2 size})
      : super(position: position, size: size) {
    add(RectangleHitbox(collisionType: CollisionType.active));
  }
}