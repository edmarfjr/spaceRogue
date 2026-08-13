import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:spacerogue/game/components/utils/palette.dart';
import 'package:spacerogue/game/components/enemies/enemy.dart'; // Mude para base_enemy se refatorou
import 'package:spacerogue/game/components/map/obstacle.dart';
import 'package:spacerogue/game/components/player/player.dart';

class ExplosionHitbox extends PositionComponent with CollisionCallbacks {
  double lifeTime = 0.2; 
  int dmgPlr;
  int dmgEnemy;

  final Set<PositionComponent> _hitEntities = {};

  ExplosionHitbox({required Vector2 position, this.dmgPlr = 1, this.dmgEnemy = 1}) 
      // Começamos a explosão um pouco menor (48x48) para ela ter espaço para crescer
      : super(position: position, size: Vector2(48, 48), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // CORREÇÃO 1: isSolid = true garante que o interior do círculo também seja "sólido"
    add(CircleHitbox(isSolid: true, collisionType: CollisionType.active));
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
    final paintV = Paint()..color = Palette.vermelho..style = PaintingStyle.stroke..filterQuality = FilterQuality.none;
    // Desenha o clarão visual
    final paintB = Paint()..color = Palette.branco..style = PaintingStyle.stroke..filterQuality = FilterQuality.none;
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

    print(other);

    if (other is Rock) {
      other.blowUp(); 
    } else if (other is Enemy) { 
      other.takeDamage(10); 
    } else if (other is Player) {
      other.takeDamage(1); 
    }
  }
}