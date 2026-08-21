import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/items/heart_half_pickup.dart';
import 'package:creatures_rogue/game/components/items/heart_pickup.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';

/// Quanto e pra onde empurrar [corpo] pra tirá-lo de dentro de [alvo]: o eixo
/// de menor penetração (MTV — minimum translation vector). Zero se não há
/// sobreposição.
///
/// Por que empurrar em vez de voltar pra posição do frame anterior: aquela
/// posição pode JÁ estar dentro do obstáculo — knockback, esbarrão de outro
/// inimigo, ou resolução incompleta do frame passado colocam a entidade dentro
/// da parede antes do frame começar. Nesse caso voltar não separa nada, o
/// mesmo overlap reaparece no frame seguinte, e a entidade fica presa pra
/// sempre. Empurrar pela profundidade real sempre separa.
///
/// Só um eixo é mexido de propósito: preservar o outro é o que faz quem anda
/// na diagonal deslizar pela parede em vez de travar.
Vector2 empurraoParaFora({required Rect corpo, required Rect alvo}) {
  final sobreposicaoX = min(corpo.right, alvo.right) - max(corpo.left, alvo.left);
  final sobreposicaoY = min(corpo.bottom, alvo.bottom) - max(corpo.top, alvo.top);

  if (sobreposicaoX <= 0 || sobreposicaoY <= 0) return Vector2.zero();

  if (sobreposicaoX < sobreposicaoY) {
    final sinal = corpo.center.dx < alvo.center.dx ? -1.0 : 1.0;
    return Vector2(sobreposicaoX * sinal, 0);
  }
  final sinal = corpo.center.dy < alvo.center.dy ? -1.0 : 1.0;
  return Vector2(0, sobreposicaoY * sinal);
}

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