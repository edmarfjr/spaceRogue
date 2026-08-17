import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/enemies/enemy_mixins.dart';
import '../enemy.dart'; 

class FlyExplodeEnemy extends Enemy with ChaseMovement {
  FlyExplodeEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         hitboxSize:Vector2(10,10),
         spritePath: 'actors/fly2.png',
         animationData: SpriteAnimationData.sequenced(
           amount: 2, 
           stepTime: 0.1, 
           textureSize: Vector2(16, 16),
         ),
         speed: 20.0,
         health: 3,
         corClara: Palette.indigo, 
         corEscura: Palette.burgundy, 
         shadowOffset: Vector2(0, 8),
         isAirborne: true,
       );

  // A Inteligência Artificial exclusiva do Slime (Perseguição Simples)
  @override
  void movimento(double dt) {
    // Só chama o método do Mixin e pronto!
    updateChaseMovement(dt);
  }

  @override
   void death() {
    List<Vector2> directions = [
      Vector2(-1, -1), 
      Vector2(1, 1),  
      Vector2(-1, 1), 
      Vector2(1, -1),  
    ];
    for (var dir in directions) {
      shoot(dir);
    }
    super.death();
  }
}
