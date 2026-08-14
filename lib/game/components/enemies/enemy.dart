import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/map/obstacle.dart';
import 'package:spacerogue/game/components/map/wall_barrier.dart';
import 'package:spacerogue/game/components/projeteis/projectile.dart';
import '../player/player.dart';
import '../utils/palette_swapper.dart'; 

abstract class Enemy extends PositionComponent with CollisionCallbacks, HasGameRef {
  final Player playerTarget;
  
  double speed; 
  double health; 
  int dmg;
  double bltSpeed;
  String bltImg;
  Color bltCor1;
  Color bltCor2;

  Color corClara;
  Color corEscura;
  Color corBranco;
  late Vector2 hitboxSize;

  final String spritePath;
  final SpriteAnimationData animationData;

  late Vector2 _previousPosition;
  late final SpriteAnimationComponent visual;

  Vector2 knockbackVelocity = Vector2.zero();

  Enemy({
    required Vector2 position, 
    required this.playerTarget,
    required this.spritePath,
    required this.animationData,
    this.speed = 30.0,
    this.health = 3,
    this.dmg = 1,
    this.bltSpeed = 150,
    this.bltCor1 = Palette.vermelho,
    this.bltCor2 = Palette.laranja,
    this.bltImg = 'projeteis/tiro.png',
    this.corClara = Palette.cinza, 
    this.corEscura = Palette.cinzaEsc,
    this.corBranco = Palette.branco,
    Vector2? size, 
    Vector2? hitboxSize,
  }) : super(
         position: position, 
         size: size ?? Vector2(16, 16), // Tamanho VISUAL padrão
         anchor: Anchor.center,
       ) {
    _previousPosition = position.clone();
    
    // Se não passar um tamanho de hitbox, ele assume que é igual ao tamanho visual
    this.hitboxSize = hitboxSize ?? (size ?? Vector2(16, 16));
  }

  @override
  Future onLoad() async {
    final ui.Image enemyImage = await PaletteSwapper.createSwappedImage(
      imagePath: spritePath,
      lightGrayReplacement: corClara,
      darkGrayReplacement: corEscura,
      whiteReplacement: corBranco,
    );

    final anim = SpriteAnimation.fromFrameData(enemyImage, animationData);

    visual = SpriteAnimationComponent(
      animation: anim,
      size: size,
      paint: Paint()..filterQuality = FilterQuality.none, 
    );
    add(visual);
    add(RectangleHitbox(collisionType: CollisionType.active));
  }

  @override
  void update(double dt) {
    _previousPosition = position.clone();
    super.update(dt);

    if (!knockbackVelocity.isZero()) {
      position += knockbackVelocity * dt;
      
      double drop = 120.0 * dt; // Atrito
      if (knockbackVelocity.length < drop) {
        knockbackVelocity.setZero();
      } else {
        knockbackVelocity -= knockbackVelocity.normalized() * drop;
      }
      return; // Pula o método de movimento, o inimigo não "pensa" enquanto voa pra trás
    }
    
    movimento(dt); 
  }

  void movimento(double dt);

  void shoot(Vector2 direction) {
    parent?.add(Projectile(
      position: position.clone() + direction*size.x/2, 
      direction: direction,
      isEnemy: true,
      speed: bltSpeed,
      dmg: dmg.toDouble(),
      sprPath: bltImg,
      cor1: bltCor1,
      cor2: bltCor2,
    ));
  }

  void takeDamage(double amount) {
    health -= amount; 
    if (health <= 0) {
      removeFromParent();
    }
  }

  void applyKnockback(Vector2 sourcePosition, double force) {
    Vector2 direction = (absolutePosition - sourcePosition).normalized();
    knockbackVelocity = direction * force;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) { 
    super.onCollisionStart(intersectionPoints.cast<Vector2>(), other);

    if (other is Projectile) {
      if (other.isEnemy) return; 

      takeDamage(other.dmg); 
      
      visual.paint.colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcATop);
      
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!isRemoved) {
          visual.paint.colorFilter = null; 
        }
      });
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy) {
      Vector2 separationVector = absolutePosition - other.absolutePosition;
      
      if (separationVector.length > 0) {
        position += separationVector.normalized() * 0.5; 
      } else {
        position.x += 0.5; 
      }
      return;
    }
    if (other is WallBarrier || other is Obstacle) {
      knockbackVelocity.setZero();
      Vector2 collisionCenter = Vector2.zero();
      for (var point in intersectionPoints) {
        collisionCenter += point;
      }
      collisionCenter /= intersectionPoints.length.toDouble();

      Vector2 diff = absolutePosition - collisionCenter;
      
      if (diff.x.abs() > diff.y.abs()) {
        position.x = _previousPosition.x;
      } else {
        position.y = _previousPosition.y;
      }
    }
  }
}