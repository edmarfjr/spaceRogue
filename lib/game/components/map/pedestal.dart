import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/items/power_up_item.dart';
import 'package:spacerogue/game/components/map/obstacle.dart';

class PedestalComponent extends Obstacle {
  late final Sprite pedestalSprite;
  
  bool hasItem = true;

  PedestalComponent({required super.position, required PowerUpType powerUpType,super.cor1 = Palette.indigo,super.cor2 = Palette.cinzaEsc}) 
      : super(
          spritePath: 'tileset/pedestal.png',
          size: Vector2(16, 16),
          collisionType: CollisionType.passive,
        ) {
    
    add(PowerUpItem(
      position: Vector2(8, -4),
      type: powerUpType,
    ));
  }
/*
  @override
  Future onLoad() async {
    // Crie um pedestal.png na sua pasta assets/images/
    
    // Colisão física para o jogador não conseguir atravessar o pedestal por cima
    add(RectangleHitbox(
      size: Vector2(12, 12), 
      anchor: Anchor.center, 
      position: size / 2, 
      collisionType: CollisionType.passive,
    ));
  }

  @override
  void render(Canvas canvas) {
    pedestalSprite.render(canvas, size: size, overridePaint: paint);
  }
  */
}