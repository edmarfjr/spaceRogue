import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/audio/game_audio.dart';
import 'package:creatures_rogue/game/audio/sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/creature_type.dart';
import 'package:creatures_rogue/game/components/creatures/damageable_by_enemy.dart';
import 'package:creatures_rogue/game/components/effects/dot.dart';
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
  bool noChao;
  final CreatureType tipo;
  final DotKind? dotKind;
  final int dotTicks;
  final double lentidaoDuracao;
  final double lentidaoFator;
  final double cegoDuracao;

  bool atravessaObstaculos;

  Map<PositionComponent,double> hits = {};
  final double hitCooldown = 0.3;
  final double? lifeTime;
  double lifeTimeIni = 10;
  double _age = 0;

  final bool estilhaca;
  final bool playSfx;

  final PositionComponent owner;

  Projectile({
    required Vector2 position,
    required this.direction,
    required this.owner,
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
    this.tipo = CreatureType.neutro,
    this.dotKind,
    this.dotTicks = 1,
    this.lentidaoDuracao = 0,
    this.lentidaoFator = 0.5,
    this.cegoDuracao = 0,
    this.atravessaObstaculos = false,
    this.estilhaca = false,
    this.playSfx = true,
    this.noChao = false,
    Vector2? size,
    int priority = 0,
    }): super(
      position: position,
      size: size ?? Vector2(16, 16),
      anchor: Anchor.center,
      priority: priority,
    );

  @override
  Future<void> onLoad() async {
    final sfx = tipo.attackSfx;
    if (sfx != null && playSfx) GameAudio.instance.play(sfx);

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
          owner: owner, 
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
          tipo: tipo,
          dotKind: dotKind,
          dotTicks: dotTicks,
          playSfx: false,
        ));
      }
    }
    if(explosionSize > 0){
      parent?.add(ExplosionHitbox(
        position: position.clone(),
        size:Vector2(explosionSize, explosionSize),
        tipo: tipo,
        isEnemy: isEnemy,
      ));
    }

    if(estilhaca){
      final anguloRad = 20 * pi / 180;
      for (final offset in [-anguloRad, 0.0, anguloRad]) {
        final rotated = direction.clone()..rotate(offset);
          parent?.add(Projectile(
          owner: owner,
          position: position.clone(),
          direction: rotated*-1,
          speed: speed,
          dmg: dmg,
          lifeTime: lifeTime,
          sprPath: sprPath,
          cor1: cor1,
          cor2: cor2,
          isEnemy: isEnemy,
          tipo: tipo,
          playSfx: false,
        ));
      }

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

    if((noChao && (other is Projectile && !other.noChao))
    ||(!noChao && (other is Projectile && other.noChao))
    ){
      return;
    }

    if (isEnemy) {
      if(other is Projectile && !other.isEnemy){
        _resolverColisaoEntreProjeteis(other);
        return;
      }
      
      if (other is DamageableByEnemy) {
        if(noChao && other is Player && other.isAirborne){
          return;
        }
        if(other.refleteProjetil){
          refleteProjetil(other);
          onDestroy();
        }
        if (lentidaoDuracao > 0) other.aplicarLentidao(lentidaoDuracao, fator: lentidaoFator);
        if (cegoDuracao > 0) other.aplicarCegueira(cegoDuracao);

        if (dmg > 0) {
          other.takeDamage(dmg);
          atravessa--;
          if (atravessa <= 0) onDestroy();
        }
      }
    } else {
      if(other is Projectile && other.isEnemy){
        _resolverColisaoEntreProjeteis(other);
        return;
      }
      if (other is Enemy) {
        if (hits.containsKey(other)) {
          return; 
        }
        if (!other.enemyHitbox.toAbsoluteRect().overlaps(toAbsoluteRect())) {
          return; 
        }
        hits[other] = hitCooldown;
        final kind = dotKind;
        if (kind != null) other.applyDot(kind, dotTicks);
        if (lentidaoDuracao > 0) other.applyLentidao(lentidaoDuracao, fator: lentidaoFator);
        if (cegoDuracao > 0) other.applyCego(cegoDuracao);

        other.takeDamage(dmg * Player.danoMult, tipoAtacante: tipo);
        other.applyKnockback(absolutePosition, kbForce);
        atravessa--;
        if (atravessa <= 0) onDestroy();
        
      }
    }
  }

  void _resolverColisaoEntreProjeteis(Projectile other) {
    if (typeMultiplier(tipo, other.tipo) > 1.0) return;
    onDestroy();
  }

  void refleteProjetil(PositionComponent owner) {
    parent?.add(Projectile(
          owner: owner,
          position: position.clone(),
          direction: direction.clone()*-1,
          speed: speed,
          dmg: dmg,
          kbForce: kbForce,
          lifeTime: lifeTimeIni,
          sprPath: sprPath,
          cor1: cor1,
          cor2: cor2,
          tipo: tipo, 
        ));
  }
}
