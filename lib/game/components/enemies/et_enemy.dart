import 'package:flame/components.dart';
import 'package:spacerogue/game/components/utils/palette.dart';
import 'enemy.dart'; 

class EtEnemy extends Enemy {
  EtEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         spritePath: 'actors/et.png',
         animationData: SpriteAnimationData.sequenced(
           amount: 3, 
           stepTime: 0.15, 
           textureSize: Vector2(16, 16),
         ),
         speed: 30.0,
         health: 3,
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