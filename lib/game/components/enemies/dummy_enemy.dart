import 'package:creatures_rogue/game/components/core/palette.dart';
import 'enemy.dart';

class DummyEnemy extends Enemy {
  DummyEnemy({
    required super.position,
    required super.playerTarget,
  }) : super(
         spritePath: 'actors/dummy.png',
         speed: 0,
         health: 100,
         corClara: Palette.verdeEsc, 
         corEscura: Palette.forest, 
         dmg:0,
       );

 @override
  void movimento(double dt) {
  }
}