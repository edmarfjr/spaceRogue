import 'dart:math';
import 'dart:ui' as ui;
import 'package:creatures_rogue/game/components/items/coin_pickup.dart';
import 'package:creatures_rogue/game/components/utils/y_sort.dart';
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

  // Distância real pra sair por cada um dos quatro lados. A versão anterior
  // comparava a SOBREPOSIÇÃO de cada eixo, que satura no tamanho do corpo
  // quando o corpo é menor que o obstáculo — e a hitbox dos pés é sempre 2:1
  // (largura `x`, altura `x / 2`). Numa parede lateral (alta), a sobreposição
  // em Y travava na altura dos pés enquanto a de X crescia, então bastava
  // afundar essa mesma altura pra que o eixo Y virasse "o mais raso": o
  // empurrão saía pra cima/baixo em vez de devolver o corpo pra dentro da
  // sala. O corpo escorregava rente à parede, continuava afundando e saía do
  // outro lado. Com distância de saída em vez de sobreposição, o eixo só
  // inverte depois de passar da metade da parede.
  final paraEsquerda = corpo.right - alvo.left;
  final paraDireita = alvo.right - corpo.left;
  final paraCima = corpo.bottom - alvo.top;
  final paraBaixo = alvo.bottom - corpo.top;

  final saidaX = min(paraEsquerda, paraDireita);
  final saidaY = min(paraCima, paraBaixo);

  if (saidaX < saidaY) {
    return Vector2(paraEsquerda < paraDireita ? -paraEsquerda : paraDireita, 0);
  }
  return Vector2(0, paraCima < paraBaixo ? -paraCima : paraBaixo);
}

abstract class Obstacle extends PositionComponent with HasGameRef {
  /// Criado junto com o componente, não dentro do `onLoad`. A porta liga e
  /// desliga a colisão pelo hitbox, e enquanto ele só existia depois do
  /// `onLoad` (que espera trocas de paleta) um `close()` chamado antes disso
  /// buscava o filho, não achava nada e virava no-op silencioso — a porta
  /// ficava trancada na lógica e atravessável na prática.
  late final RectangleHitbox hitbox =
      RectangleHitbox(collisionType: collisionType);

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
    add(hitbox);
    
    final ui.Image swappedImage = await PaletteSwapper.createSwappedImage(
      imagePath: spritePath,
      lightGrayReplacement: cor1,
      darkGrayReplacement: cor2,
      whiteReplacement: cor3,
    );
    
    obstacleSprite = Sprite(swappedImage);
    
    paint.filterQuality = FilterQuality.none;
    priority = ySortPriority(position.y + size.y / 2);
  }

  @override
  void render(Canvas canvas) {
    obstacleSprite.render(canvas, size: size, overridePaint: paint);
  }
}

class Rock extends Obstacle {
  Rock({
    required super.position,
    String sprPath = 'tileset/pedra.png',
    super.cor1,
    super.cor2,
    super.cor3,
    Vector2? size,
  }) : super(
         spritePath: sprPath, 
         size: size ?? Vector2(16, 16),
         collisionType: CollisionType.active, 
       );

  void blowUp() {
    final random = Random();
    
    if (random.nextDouble() < 0.05) {
      double itemChance = random.nextDouble();
      if (itemChance <= 0.05) {
        parent?.add(HeartPickup(position: position.clone()));
      } else if (itemChance > 0.05 && itemChance <= 0.15) {  
        parent?.add(HeartHalfPickup(position: position.clone()));
      }else{
        parent?.add(CoinPickup(position: position.clone()));
      }
    }

    removeFromParent(); 
  }
}

class Hole extends Obstacle {
  Hole({
    required super.position,
    Vector2? size,
    super.cor1,
    super.cor2,
    super.cor3,
  }) : super(
         spritePath: 'tileset/hole.png',
         size: size ?? Vector2(16, 16),
         collisionType: CollisionType.active,
       );
  
}

class Grama extends Obstacle {
  Grama({
    required super.position,
    Vector2? size,
    super.cor1,
    super.cor2,
    super.cor3,
  }) : super(
         spritePath: 'tileset/floor3.png',
         size: size ?? Vector2(16, 16),
         collisionType: CollisionType.inactive,
       );
}

class GramaAlta extends Obstacle {
  GramaAlta({
    required super.position,
    Vector2? size,
    super.cor1,
    super.cor2,
    super.cor3,
  }) : super(
         spritePath: 'tileset/gramaAlta.png',
         size: size ?? Vector2(16, 16),
         collisionType: CollisionType.active,
       );
}