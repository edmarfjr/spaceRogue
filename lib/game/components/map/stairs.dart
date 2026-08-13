import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:spacerogue/game/space_rogue_game.dart';

import '../player/player.dart';

class Stairs extends PositionComponent with CollisionCallbacks, HasGameRef<SpacerogueGame> {
  late final Sprite sprite;
  final Paint _paint = Paint()..filterQuality = FilterQuality.none;

  Stairs({required Vector2 position}) 
      : super(position: position, size: Vector2(16, 16), anchor: Anchor.center);

  @override
  Future onLoad() async {
    // Crie um trapdoor.png na sua pasta de assets
    sprite = await gameRef.loadSprite('tileset/stairs.png');
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void render(Canvas canvas) {
    sprite.render(canvas, size: size, overridePaint: _paint);
  }

  @override
  void onCollisionStart(Set intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints.cast(), other);
    
    if (other is Player) {
      // Quando o jogador pisa no alçapão, chama a função de avançar nível
      gameRef.nextLevel();
    }
  }
}
