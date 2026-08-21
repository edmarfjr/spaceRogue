import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/UI/ability_cooldown_indicator.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import '../player/player.dart';

class Hud extends PositionComponent with HasGameRef {
  final Player player;
  // Sprites
  late final Sprite heartSprite;
  late final Sprite heartHalfSprite;
  late final Sprite heartEmptySprite;
  //late final Sprite bombSprite;
  
  final Paint emptyHeartPaint = Paint()
    ..colorFilter = const ColorFilter.mode(Palette.preto, BlendMode.srcATop)
    ..filterQuality = FilterQuality.none;

  final Paint paint = Paint()..filterQuality = FilterQuality.none;

  late final TextPaint textPaint;

  final Vector2 heartSize = Vector2(16, 16);
  final Vector2 bombIconSize = Vector2(16, 16);
  final double spacing = -13.0;

  /// Lado dos indicadores de cooldown. 16 é o tamanho nativo dos sprites
  /// (`ui/ataque.png` e `ui/defesa.png`), então a escala fica 1:1 e o pixel art
  /// não ganha artefato de reamostragem.
  static const double _iconeCooldownLado = 16;

  static final Vector2 _shieldBarSize = Vector2(3, 3);
  final Paint _shieldMoldura = Paint()..color = Palette.branco;
  final Paint _shieldFundo = Paint()..color = Palette.preto;
  final Paint _shieldPreenchimento = Paint()..color = Palette.azul;
  final Paint _hpPreenchimento = Paint()..color = Palette.vermelho;
  

  Hud({required this.player}) : super(position: Vector2(2, 2));

  @override
  Future<void> onLoad() async {
    super.onLoad();
/*
    final ui.Image heartImg = await PaletteSwapper.createSwappedImage(
      imagePath: 'ui/heart.png',
      lightGrayReplacement: Palette.vermelho,
      darkGrayReplacement: Palette.roxoEsc,
    );

    final ui.Image heartHalfImg = await PaletteSwapper.createSwappedImage(
      imagePath: 'ui/heartHalf.png',
      lightGrayReplacement: Palette.vermelho,
      darkGrayReplacement: Palette.roxoEsc,
    );

    final ui.Image heartEmptyImg = await PaletteSwapper.createSwappedImage(
      imagePath: 'ui/heartEmpty.png',
      lightGrayReplacement: Palette.vermelho,
      darkGrayReplacement: Palette.roxoEsc,
    );
    
    final ui.Image bombImg = await PaletteSwapper.createSwappedImage(
      imagePath: 'ui/bomb.png',
      lightGrayReplacement: Palette.picotronBege,
      darkGrayReplacement: Palette.azulEsc,
    );
    
    heartSprite = Sprite(heartImg);
    heartHalfSprite = Sprite(heartHalfImg);
    heartEmptySprite = Sprite(heartEmptyImg);
*/
    //bombSprite = Sprite(bombImg);

    // Indicadores de cooldown, logo abaixo das barras de vida/escudo. Ficam
    // como filhos e não dentro do render() da Hud pra cada um cuidar do seu
    // próprio sprite e do seu carregamento assíncrono.
    await addAll([
      AbilityCooldownIndicator(
        spritePath: 'ui/ataque.png',
        cooldownFraction: () => player.ability1CooldownFraction,
        lado: _iconeCooldownLado,
        position: Vector2(0, 12),
      ),
      AbilityCooldownIndicator(
        spritePath: 'ui/defesa.png',
        cooldownFraction: () => player.ability2CooldownFraction,
        lado: _iconeCooldownLado,
        position: Vector2(_iconeCooldownLado + 2, 12),
      ),
    ]);

    textPaint = TextPaint(
      style: const TextStyle(
        fontFamily: 'pixelFont',
        color: Palette.branco,
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

    canvas.drawRect(Rect.fromLTWH(-1, 3 - 1, _shieldBarSize.x * player.maxHealth + 2, _shieldBarSize.y + 2), _shieldMoldura);
    canvas.drawRect(Rect.fromLTWH(0, 3, _shieldBarSize.x * player.maxHealth, _shieldBarSize.y), _shieldFundo);
    canvas.drawRect(Rect.fromLTWH(0, 3, _shieldBarSize.x * player.currentHealth, _shieldBarSize.y), _hpPreenchimento);


    canvas.drawRect(Rect.fromLTWH(-1, 7 - 1, _shieldBarSize.x * player.shieldMax + 2, _shieldBarSize.y + 2), _shieldMoldura);
    canvas.drawRect(Rect.fromLTWH(0, 7, _shieldBarSize.x * player.shieldMax, _shieldBarSize.y), _shieldFundo);
    canvas.drawRect(Rect.fromLTWH(0, 7, _shieldBarSize.x * player.shield, _shieldBarSize.y), _shieldPreenchimento);
/*
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
        overridePaint: paint
      );
    }

    // --- BARRA DE ESCUDO PASSIVO (defesa) ---
    if (player.shieldMax > 0) {
      final shieldY = heartSize.y + 1;
      final fracao = (player.shield / player.shieldMax).clamp(0.0, 1.0);

      canvas.drawRect(Rect.fromLTWH(-1, shieldY - 1, _shieldBarSize.x + 2, _shieldBarSize.y + 2), _shieldMoldura);
      canvas.drawRect(Rect.fromLTWH(0, shieldY, _shieldBarSize.x, _shieldBarSize.y), _shieldFundo);
      canvas.drawRect(Rect.fromLTWH(0, shieldY, _shieldBarSize.x * fracao, _shieldBarSize.y), _shieldPreenchimento);
    }
*/

    //double bombY = heartSize.y + 2;
    //bombSprite.render(canvas, position: Vector2(0, bombY), size: bombIconSize, overridePaint: paint);
    //textPaint.render(canvas, ':${player.bombsAmount}', Vector2(bombIconSize.x + 0, bombY+1));
  }
}