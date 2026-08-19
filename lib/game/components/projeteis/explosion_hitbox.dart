import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/enemies/enemy.dart'; // Mude para base_enemy se refatorou
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/components/player/player.dart';

class ExplosionHitbox extends PositionComponent with CollisionCallbacks {
  double lifeTime = 0.2;
  double dmg;

  /// Se true, além do dano, atordoa (zera a ação) os inimigos atingidos.
  final bool isStun;
  final double stunDuration;
  final bool isEnemy;
  final Color cor1;
  final Color cor2;

  /// Força de empurrão aplicada aos inimigos atingidos. 0 = não empurra.
  final double knockback;

  Paint paintV = Paint();
  Paint paintB = Paint();

  final Set<PositionComponent> _hitEntities = {};

  ExplosionHitbox({
    required Vector2 position,
    this.dmg = 1,
    this.isStun = false,
    this.isEnemy = false,
    this.stunDuration = 1.5,
    this.knockback = 0.0,
    this.cor1 = Palette.vermelho,
    this.cor2 = Palette.branco,
    Vector2? size,
  })
      : super(position: position, size: size ?? Vector2(32, 32), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // CORREÇÃO 1: isSolid = true garante que o interior do círculo também seja "sólido"
    add(CircleHitbox(isSolid: true, collisionType: CollisionType.active));

    paintV = Paint()
    ..color = cor1
    ..style = PaintingStyle.stroke
    ..filterQuality = FilterQuality.none;

    paintB = Paint()
    ..color = cor2
    ..style = PaintingStyle.stroke
    ..filterQuality = FilterQuality.none;
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifeTime -= dt;

    // CORREÇÃO 2: Aumentamos o tamanho (scale) da explosão rapidamente a cada frame!
    // Isso força o motor de física a se atualizar e gera um efeito de onda de choque.
    scale += Vector2.all(dt * 5); 

    if (lifeTime <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    // Desenha o clarão visual
    canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/2, paintB);
    canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/2 + 1, paintV);
    canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/2 - 1, paintV);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints.cast<Vector2>(), other);
    
    if (_hitEntities.contains(other)) return; 
    _hitEntities.add(other);

    if (other is Rock) {
      other.blowUp();
    } else if (other is Enemy && !isEnemy) {
      other.takeDamage(dmg);
      if (isStun) other.stunTimer = stunDuration;
      if (knockback > 0) other.applyKnockback(absolutePosition, knockback);
    } else if (other is Player && isEnemy) {
      other.takeDamage(dmg.toInt());
      if (knockback > 0) other.applyKnockback(absolutePosition, knockback);
    }
  }
}