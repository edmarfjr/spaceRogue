import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:spacerogue/game/components/projeteis/explosion_hitbox.dart';


// 1. A BOMBA
class Bomb extends SpriteAnimationComponent with HasGameRef {
  double timer = 2.0; // 2 segundos até explodir

  Bomb({required Vector2 position}) 
      : super(position: position, size: Vector2(16, 16), anchor: Anchor.center);

  @override
  Future onLoad() async {
    // Crie um bomb_anim.png ou carregue um sprite fixo por enquanto
    animation = await gameRef.loadSpriteAnimation(
      'projeteis/bomb.png',
      SpriteAnimationData.sequenced(amount: 2, stepTime: 0.2, textureSize: Vector2(16, 16)),
    );
    paint = Paint()..filterQuality = FilterQuality.none;
  }

  @override
  void update(double dt) {
    super.update(dt);
    timer -= dt;
    
    // Efeito visual acelerando o piscar da bomba perto de explodir
    if (timer < 0.5) animation?.stepTime = 0.05;

    if (timer <= 0) {
      _explode();
    }
  }

  void _explode() {
    final currentWorld = parent; 
    currentWorld?.add(ExplosionHitbox(position: position.clone(), dmgPlr: 2, dmgEnemy: 10));
    
    removeFromParent();
  }
}

