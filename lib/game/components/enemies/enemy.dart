import 'dart:ui' as ui; // Importante para o ui.Image
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:spacerogue/game/components/utils/palette.dart';
import 'package:spacerogue/game/components/map/obstacle.dart';
import 'package:spacerogue/game/components/map/wall_barrier.dart';
import 'package:spacerogue/game/components/projeteis/projectile.dart';
import '../player/player.dart';
import '../utils/palette_swapper.dart'; // Ajuste o caminho do PaletteSwapper se necessário

abstract class Enemy extends PositionComponent with CollisionCallbacks, HasGameRef {
  final Player playerTarget;
  
  double speed; 
  double health; 
  int dmg;

  // Substituímos baseColor por corClara e corEscura
  Color corClara;
  Color corEscura;

  final String spritePath;
  final SpriteAnimationData animationData;

  Vector2 _previousPosition = Vector2.zero();
  late final SpriteAnimationComponent visual;

  Enemy({
    required Vector2 position, 
    required this.playerTarget,
    required this.spritePath,
    required this.animationData,
    this.speed = 30.0,
    this.health = 3,
    this.dmg = 1,
    this.corClara = Palette.branco, // Cor padrão clara
    this.corEscura = Palette.cinza, // Cor padrão escura
  }) : super(position: position, size: Vector2(16, 16), anchor: Anchor.center);

  @override
  Future onLoad() async {
    // 1. Carrega a imagem com os bytes modificados pelo PaletteSwapper
    final ui.Image enemyImage = await PaletteSwapper.createSwappedImage(
      imagePath: spritePath,
      lightGrayReplacement: corClara,
      darkGrayReplacement: corEscura,
    );

    // 2. Cria a animação a partir da nova imagem colorida
    final anim = SpriteAnimation.fromFrameData(enemyImage, animationData);

    visual = SpriteAnimationComponent(
      animation: anim,
      size: size,
      paint: Paint()..filterQuality = FilterQuality.none, // Removemos o colorFilter inicial daqui!
    );
    add(visual);
    add(RectangleHitbox(collisionType: CollisionType.active));
  }

  @override
  void update(double dt) {
    _previousPosition = position.clone();
    super.update(dt);
    
    movimento(dt); 
  }

  void movimento(double dt);

  void shoot(Vector2 direction) {
    parent?.add(Projectile(
      position: position.clone(), 
      direction: direction,
      isEnemy: true,
      speed: 150.0,
      cor: Palette.vermelho
    ));
  }

  void takeDamage(int amount) {
    health -= amount; 
    if (health <= 0) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) { 
    super.onCollisionStart(intersectionPoints.cast<Vector2>(), other);

    if (other is Projectile) {
      if (other.isEnemy) return; 

      takeDamage(other.dmg); 
      
      // 1. Aplica o filtro branco para o flash de dano
      visual.paint.colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcATop);
      
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!isRemoved) {
          // 2. CORREÇÃO: Como a imagem já tem a cor real, apenas removemos o filtro branco!
          visual.paint.colorFilter = null; 
        }
      });
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    if (other is WallBarrier || other is Obstacle) {
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