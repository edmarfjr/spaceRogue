import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/enemies/enemy_mixins.dart';
import 'package:spacerogue/game/components/map/obstacle.dart';
import 'package:spacerogue/game/components/map/wall_barrier.dart';
import '../enemy.dart'; 

class BatEnemy extends Enemy with WanderMovement {

  BatEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         size: Vector2(16, 16),
         // Deixamos a hitbox ligeiramente menor para ele deslizar melhor nos obstáculos
         hitboxSize: Vector2(12, 12), 
         
         // Ajuste o nome para o seu sprite (ex: morcego.png)
         spritePath: 'actors/bat.png', 
         animationData: SpriteAnimationData.sequenced(
           amount: 2, 
           stepTime: 0.15, 
           textureSize: Vector2(16, 16),
         ),
         speed: 35.0, // Velocidade de caminhada
         health: 2,
         corClara: Palette.laranja, 
         corEscura: Palette.marromEsc, 
         shadowOffset: Vector2(0, 8),
       );

  @override
  void movimento(double dt) {
    updateWanderMovement(dt,minPause: 0,maxPause: 0);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is WallBarrier || other is Obstacle){
      if (!isPhysicsCollision(other)) return; 
      cancelWander(); 
    } 
  }
}