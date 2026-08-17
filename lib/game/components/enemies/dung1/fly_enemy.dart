import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/enemies/enemy_mixins.dart';
import '../enemy.dart'; 

class FlyEnemy extends Enemy with ChaseMovement {
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
         shadowOffset: Vector2(0, 8),
         isAirborne: true,
       );

  // A Inteligência Artificial exclusiva do Slime (Perseguição Simples)
  @override
  void movimento(double dt) {
    // Só chama o método do Mixin e pronto!
    updateChaseMovement(dt);
  }
}