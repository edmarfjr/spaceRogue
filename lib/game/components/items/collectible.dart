import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import '../player/player.dart';

// A classe é abstrata, não pode ser instanciada diretamente.
abstract class Collectible extends PositionComponent with CollisionCallbacks, HasGameRef {
  final String spritePath; // Cada filho dirá qual imagem carregar
  
  late final Sprite _sprite;
  final Paint _paint = Paint()..filterQuality = FilterQuality.none;

  Collectible({
    required Vector2 position,
    required this.spritePath,
  }) : super(position: position, size: Vector2(16, 16), anchor: Anchor.center);

  @override
  Future onLoad() async {
    _sprite = await gameRef.loadSprite(spritePath);
    
    add(RectangleHitbox(
      size: Vector2(10, 10),
      anchor: Anchor.center,
      position: size / 2,
      collisionType: CollisionType.passive,
    ));
  }

  @override
  void render(Canvas canvas) {
    _sprite.render(canvas, size: size, overridePaint: _paint);
  }

  @override
  void onCollisionStart(Set intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints.cast(), other);
    
    if (other is Player) {
      // Chama o método abstrato que os filhos vão implementar
      bool wasCollected = onCollect(other); 
      
      if (wasCollected) {
        removeFromParent();
      }
    }
  }

  // NOVO: Método abstrato!
  // Retorna 'true' se o item foi consumido, ou 'false' se não (ex: vida já estava cheia)
  bool onCollect(Player player); 
}