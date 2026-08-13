import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:spacerogue/game/components/utils/palette.dart';
import '../player/player.dart';

class Hud extends PositionComponent with HasGameRef {
  final Player player;
  
  // Sprites
  late final Sprite heartSprite;
  late final Sprite heartHalfSprite;
  late final Sprite heartEmptySprite;
  late final Sprite bombSprite;
  
  final Paint emptyHeartPaint = Paint()
    ..colorFilter = const ColorFilter.mode(Palette.preto, BlendMode.srcATop)
    ..filterQuality = FilterQuality.none;

  final Paint fullHeartPaint = Paint()..filterQuality = FilterQuality.none..colorFilter =  ColorFilter.mode(Palette.vermelho, BlendMode.modulate);
  final Paint bombPaint = Paint()..filterQuality = FilterQuality.none..colorFilter =  ColorFilter.mode(Palette.azulEsc, BlendMode.modulate);

  late final TextPaint textPaint;

  final Vector2 heartSize = Vector2(16, 16); 
  final Vector2 bombIconSize = Vector2(16, 16); 
  final double spacing = 2.0;

  Hud({required this.player}) : super(position: Vector2(2, 2));

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    heartSprite = await gameRef.loadSprite('ui/heart.png');
    heartHalfSprite = await gameRef.loadSprite('ui/heartHalf.png');
    heartEmptySprite = await gameRef.loadSprite('ui/heartEmpty.png');


    bombSprite = await gameRef.loadSprite('ui/bomb.png');

    textPaint = TextPaint(
      style: const TextStyle(
        fontFamily: 'pixelFont',
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2), 
        ],
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // --- LÓGICA DO MEIO-CORAÇÃO ---
    // Quantos corações INICIAIS (capacidade total) o jogador tem na tela?
    // Como a escala do player é dobrada (maxHealth = 6), dividimos por 2 (3 corações na tela).
    int totalHeartsOnScreen = (player.maxHealth / 2).floor();

    // Quantos corações visualmente inteiros ele tem? (ex: vida 5 / 2 = 2 inteiros)
    int fullHearts = (player.currentHealth / 2).floor();
    
    // Tem algum resto? (ex: vida 5 % 2 = 1). Se sim, tem um meio-coração solto!
    bool hasHalfHeart = (player.currentHealth % 2) != 0;

    for (int i = 0; i < totalHeartsOnScreen; i++) {
      final xPosition = i * (heartSize.x + spacing);
      
      Sprite spriteToDraw;

      if (i < fullHearts) {
        // Desenha um coração completo
        spriteToDraw = heartSprite;
      } else if (i == fullHearts && hasHalfHeart) {
        // O próximo slot após os corações completos recebe a metade
        spriteToDraw = heartHalfSprite;
      } else {
        // O resto da capacidade máxima fica vazia
        spriteToDraw = heartEmptySprite;
      }

      spriteToDraw.render(
        canvas, 
        position: Vector2(xPosition, 0), 
        size: heartSize, 
        overridePaint: fullHeartPaint
      );
    }

    double bombY = heartSize.y + 2;
    bombSprite.render(canvas, position: Vector2(0, bombY), size: bombIconSize, overridePaint: bombPaint);
    textPaint.render(canvas, ':${player.bombsAmount}', Vector2(bombIconSize.x + 0, bombY+1));
  }
}