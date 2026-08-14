import 'package:flame/components.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'enemy.dart'; 

class DummyEnemy extends Enemy {
  DummyEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         spritePath: 'actors/dummy.png',
         animationData: SpriteAnimationData.sequenced(
           amount: 1, 
           stepTime: 0.15, 
           textureSize: Vector2(16, 16),
         ),
         speed: 0,
         health: 100,
         corClara: Palette.picotronBege, 
         corEscura: Palette.chocolate, 
         dmg:0,
       );

 @override
  void movimento(double dt) {
  }
}