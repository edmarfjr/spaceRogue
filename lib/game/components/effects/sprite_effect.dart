import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
//import 'package:spacerogue/game/components/core/palette.dart';
import '../utils/palette_swapper.dart'; 

class SpriteEffect extends SpriteAnimationComponent with HasGameRef {
  final String spritePath;
  final Color corClara;
  final Color corEscura;
  final Color corBranco;
  
  final int frames;
  final double stepTime;
  final Vector2 textureSize;

  SpriteEffect({
    required super.position,
    required this.spritePath,
    required this.corClara,
    required this.corEscura,
    required this.corBranco,
    super.size, // O tamanho físico na tela (escala)
    this.frames = 5, // Quantos quadros tem a sua animação de morte?
    this.stepTime = 0.1, // Velocidade da explosão
    Vector2? textureSize, // O tamanho do recorte na imagem original
  }) : 
       textureSize = textureSize ?? Vector2(16, 16),
       super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // 1. Aplica a paleta de cores (A explosão terá o sangue/fumaça da cor do monstro)
    final ui.Image swappedImage = await PaletteSwapper.createSwappedImage(
      imagePath: spritePath,
      lightGrayReplacement: corClara,
      darkGrayReplacement: corEscura,
      whiteReplacement: corBranco,
    );

    // 2. Carrega a animação
    animation = SpriteAnimation.fromFrameData(
      swappedImage,
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: stepTime,
        textureSize: textureSize,
        loop: false, // MÁGICA 1: A animação para no último frame!
      ),
    );

    // MÁGICA 2: O Flame destrói o componente automaticamente quando o loop = false acabar.
    removeOnFinish = true; 
  }
}