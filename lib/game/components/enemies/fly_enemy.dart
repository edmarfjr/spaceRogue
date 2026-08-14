import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'enemy.dart'; 

class FlyEnemy extends Enemy {
  FlyEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         hitboxSize:Vector2(8,8),
         spritePath: 'actors/fly.png',
         animationData: SpriteAnimationData.sequenced(
           amount: 2, 
           stepTime: 0.1, 
           textureSize: Vector2(16, 16),
         ),
         speed: 40.0,
         health: 1,
         corClara: Palette.indigo, 
         corEscura: Palette.cinzaEsc, 
       );

  // A Inteligência Artificial exclusiva do Slime (Perseguição Simples)
  @override
  void movimento(double dt) {
    Vector2 directionToPlayer = playerTarget.position - position;
    
    if (directionToPlayer.length > 2.0) {
      position += directionToPlayer.normalized() * speed * dt;

      // Espelha o sprite dependendo da direção
      if (directionToPlayer.x < 0 && !visual.isFlippedHorizontally) {
        visual.flipHorizontallyAroundCenter();
      } else if (directionToPlayer.x > 0 && visual.isFlippedHorizontally) {
        visual.flipHorizontallyAroundCenter();
      }
    }
  }
}