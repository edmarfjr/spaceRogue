import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/enemies/enemy_mixins.dart';
import '../enemy.dart'; 

class EtChaserEnemy extends Enemy with ChaseMovement {
  EtChaserEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         spritePath: 'actors/et.png',
         animationData: SpriteAnimationData.sequenced(
           amount: 3, 
           stepTime: 0.15, 
           textureSize: Vector2(16, 16),
         ),
         speed: 20.0,
         health: 3,
         corClara: Palette.roxoEsc, 
         corEscura: Palette.amarelo, 
       );

  // A Inteligência Artificial exclusiva do Slime (Perseguição Simples)
  @override
  void movimento(double dt) {
    // Só chama o método do Mixin e pronto!
    updateChaseMovement(dt);
  }
}