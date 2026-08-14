import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/items/heart_half_pickup.dart';
import 'package:spacerogue/game/components/items/heart_pickup.dart';
import 'package:spacerogue/game/components/utils/palette_swapper.dart';

abstract class Obstacle extends PositionComponent with HasGameRef {
  late final Sprite obstacleSprite;
  final String spritePath;
  final Color cor1;
  final Color cor2;
  final Color cor3;
  final CollisionType collisionType;
  
  final Paint paint = Paint()..filterQuality = FilterQuality.none;

  Obstacle({
    required Vector2 position,
    required this.spritePath,
    this.cor1 = Palette.marromEsc,
    this.cor2 = Palette.onyx,
    this.cor3 = Palette.branco,
    required Vector2 size,
    required this.collisionType,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(collisionType: collisionType));
    
    final ui.Image swappedImage = await PaletteSwapper.createSwappedImage(
      imagePath: spritePath,
      lightGrayReplacement: cor1,
      darkGrayReplacement: cor2,
      whiteReplacement: cor3,
    );
    
    obstacleSprite = Sprite(swappedImage);
    
    paint.filterQuality = FilterQuality.none;
  }

  @override
  void render(Canvas canvas) {
    obstacleSprite.render(canvas, size: size, overridePaint: paint);
  }
}

class Rock extends Obstacle {
  Rock({
    required super.position,
    String sprPath = 'tileset/rock.png',
    super.cor1,
    super.cor2,
    super.cor3,
    Vector2? size,
  }) : super(
         spritePath: sprPath, 
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