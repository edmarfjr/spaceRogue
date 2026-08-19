import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/enemies/enemy.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/projeteis/explosion_hitbox.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';

class Projectile extends SpriteAnimationComponent with CollisionCallbacks, HasGameRef {
  final Vector2 direction;
  double speed;
  bool isEnemy;
  String sprPath;
  Color cor1;
  Color cor2;
  double dmg;
  double kbForce;
  int fragmentos;
  double explosionSize;
  double radius;
  int atravessa;
  bool isPoison;
  int poisonCount;
  bool atravessaObstaculos;

  Map<PositionComponent,double> hits = {};
  final double hitCooldown = 0.3;

  /// Tempo de vida opcional, em segundos. Null = vive até colidir ou sair da tela.
  final double? lifeTime;
  double lifeTimeIni = 10;
  double _age = 0;

  Projectile({
    required Vector2 position,
    required this.direction,
    this.isEnemy = false,
    this.speed = 200,
    this.kbForce = 20,
    this.sprPath = 'projeteis/tiro.png',
    this.cor1 = Palette.azul,
    this.cor2 = Palette.verdeEsc,
    this.dmg = 1,
    this.lifeTime,
    this.fragmentos = 0,
    this.explosionSize = 0,
    this.radius = 5,
    this.atravessa = 1,
    this.isPoison = false,
    this.poisonCount = 1,
    this.atravessaObstaculos = false,
    Vector2? size, 
    }): super(
      position: position, 
      size: size ?? Vector2(16, 16),
      anchor: Anchor.center
    );

  @override
  Future<void> onLoad() async {

    lifeTimeIni = lifeTime ?? 10;

    final ui.Image img = await PaletteSwapper.createSwappedImage(
      imagePath: sprPath,
      lightGrayReplacement: cor1,
      darkGrayReplacement: cor2,
    );
    animation = SpriteAnimation.fromFrameData(
      img,
      SpriteAnimationData.sequenced(amount: (img.width/img.height).toInt(), stepTime: 0.2, textureSize: Vector2(16, 16)),
    );

    paint = Paint()..filterQuality = FilterQuality.none;
    angle = direction.screenAngle();
    add(CircleHitbox(collisionType: CollisionType.active,radius: radius,anchor: Anchor.center,position: size/2));
    //debugMode = true;
  }

  void onDestroy(){
    if(fragmentos > 0){
      for (int i = 0; i < fragmentos; i++) {
        double angle = Random().nextDouble() * 2 * pi;
        Vector2 dir = Vector2(cos(angle), sin(angle));
        parent?.add(Projectile(
          position: position.clone(),
          direction: dir,
          speed: speed,
          dmg: dmg,
          kbForce: kbForce,
          lifeTime: lifeTime,
          sprPath: sprPath,
          cor1: cor1,
          cor2: cor2,
          isEnemy: isEnemy,
        ));
      }
    }
    if(explosionSize > 0){
      parent?.add(ExplosionHitbox(
        position: position.clone(),
        size:Vector2(explosionSize, explosionSize)
      ));
    }

    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * speed * dt;

    if (hits.isNotEmpty) {
      hits.updateAll((enemy, timeRestante) => timeRestante - dt);
      hits.removeWhere((enemy, timeRestante) => timeRestante <= 0);
    }

    if (lifeTime != null) {
      _age += dt;
      if (_age >= lifeTime!) onDestroy();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if ((other is WallBarrier || other is Rock) && !atravessaObstaculos) {
      onDestroy();
      return; 
    }

    if (isEnemy) {
      if (other is Player) {
        if(other.refleteProjetil){
          refleteProjetil();
          return;
        }
        other.takeDamage(dmg.toInt());
        atravessa--;
        if(atravessa <= 0){
          onDestroy();
        } 
      }
    } else {
      if (other is Enemy) {
        if (hits.containsKey(other)) {
          return; // Bala fantasma, ignora a colisão e continua voando!
        }
        if (!other.enemyHitbox.toAbsoluteRect().overlaps(toAbsoluteRect())) {
          return; // Bala passa reto!
        }
        hits[other] = hitCooldown;
        atravessa--;
        if(isPoison){
          other.applyPoison(poisonCount);
        }
        other.takeDamage(dmg);
        other.applyKnockback(absolutePosition, kbForce);
        
        if(atravessa <= 0){
          onDestroy();
        } 
      }
    }
  }

  void refleteProjetil() {
    parent?.add(Projectile(
          position: position.clone(),
          direction: direction.clone()*-1,
          speed: speed,
          dmg: dmg,
          kbForce: kbForce,
          lifeTime: lifeTimeIni,
          sprPath: sprPath,
          cor1: cor1,
          cor2: cor2,
        ));
  }
}
