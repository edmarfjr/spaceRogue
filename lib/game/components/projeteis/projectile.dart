import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/enemies/enemy.dart';
import 'package:spacerogue/game/components/map/obstacle.dart';
import 'package:spacerogue/game/components/map/wall_barrier.dart';
import 'package:spacerogue/game/components/player/player.dart';
import 'package:spacerogue/game/components/utils/palette_swapper.dart';

class Projectile extends SpriteAnimationComponent with CollisionCallbacks, HasGameRef {
  final Vector2 direction;
  double speed;
  bool isEnemy;
  String sprPath;
  Color cor1;
  Color cor2;
  double dmg;
  double kbForce;

  Projectile({
    required Vector2 position,
    required this.direction, 
    this.isEnemy = false, 
    this.speed = 200, 
    this.kbForce = 200,
    this.sprPath = 'projeteis/tiro.png', 
    this.cor1 = Palette.azul, 
    this.cor2 = Palette.verdeEsc, 
    this.dmg = 1
    }): super(
      position: position, 
      size: Vector2(10, 10), 
      anchor: Anchor.center
    );

  @override
  Future<void> onLoad() async {

    final ui.Image img = await PaletteSwapper.createSwappedImage(
      imagePath: sprPath,
      lightGrayReplacement: cor1,
      darkGrayReplacement: cor2,
    );
    animation = SpriteAnimation.fromFrameData(
      img,
      SpriteAnimationData.sequenced(amount: 2, stepTime: 0.2, textureSize: Vector2(16, 16)),
    );

    paint = Paint()..filterQuality = FilterQuality.none;
    angle = direction.screenAngle();
    add(CircleHitbox(collisionType: CollisionType.active));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * speed * dt;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is WallBarrier || other is Rock) {
      removeFromParent();
      return; 
    }

    if (isEnemy) {
      if (other is Player) {
        other.takeDamage(dmg.toInt()); 
        removeFromParent();
      }
    } else {
      if (other is Enemy) {
        if (!other.enemyHitbox.toAbsoluteRect().overlaps(toAbsoluteRect())) {
          return; // Bala passa reto!
        }
        other.takeDamage(dmg);
        other.applyKnockback(absolutePosition, kbForce);
        removeFromParent();
      }
    }
  }
}
