import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:spacerogue/game/components/utils/palette.dart';
import 'package:spacerogue/game/components/items/heart_half_pickup.dart';
import 'package:spacerogue/game/components/items/heart_pickup.dart';

abstract class Obstacle extends PositionComponent with HasGameRef {
  late final Sprite obstacleSprite;
  final String spritePath;
  final Color? colorModulate;
  final CollisionType collisionType;
  
  final Paint paint = Paint()..filterQuality = FilterQuality.none;

  Obstacle({
    required Vector2 position,
    required this.spritePath,
    this.colorModulate,
    required Vector2 size,
    required this.collisionType,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    obstacleSprite = await gameRef.loadSprite(spritePath);
    add(RectangleHitbox(collisionType: collisionType));
    
    if (colorModulate != null) {
      paint.colorFilter = ColorFilter.mode(colorModulate!, BlendMode.modulate);
    }
  }

  @override
  void render(Canvas canvas) {
    obstacleSprite.render(canvas, size: size, overridePaint: paint);
  }
}

class Rock extends Obstacle {
  Rock({
    required Vector2 position,
    String sprPath = 'tileset/rock.png',
    Color cor = Palette.marromEsc,
    Vector2? size,
  }) : super(
         position: position,
         spritePath: sprPath,
         colorModulate: cor,
         size: size ?? Vector2(16, 16),
         collisionType: CollisionType.passive, 
       );

  void blowUp() {
    final random = Random();
    
    if (random.nextDouble() < 0.20) {
      if (random.nextBool()) {
        parent?.add(HeartPickup(position: position.clone()));
      } else {  
        parent?.add(HeartHalfPickup(position: position.clone()));
      }
    }

    removeFromParent(); 
  }
}

class Hole extends Obstacle {
  Hole({
    required super.position,
    Vector2? size,
  }) : super(
         spritePath: 'tileset/hole.png',
         size: size ?? Vector2(16, 16),
         collisionType: CollisionType.active,
       );
  
}