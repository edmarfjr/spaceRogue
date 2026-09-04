import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/UI/ability_cooldown_indicator.dart';
import 'package:creatures_rogue/game/components/UI/companion_portrait_indicator.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import '../player/player.dart';

class Hud extends PositionComponent with HasGameRef {
  final Player player;

  /// Grupo de até três — cada função recebe o índice do slot (0/1/2).
  /// `companionCreatureAt` fica fixa mesmo quando o slot está no banco
  /// (`null` até a criatura selvagem da sala da escada preencher, ver
  /// PIVOT_CONTROLE_DIRETO.md §5). Ver `CompanionPortraitIndicator`.
  final CreatureData? Function(int slot) companionCreatureAt;

  /// 0 = ativa (ou vida cheia no banco), 1 = acabou de entrar no banco com a
  /// vida zerada — ver `CreaturesRogueGame.companionPocketFraction`.
  final double Function(int slot) companionPocketFractionAt;

  /// Qual slot é a criatura ativa agora — o retrato dela ganha o destaque
  /// visual.
  final bool Function(int slot) isCompanionAtivo;

  /// Toque em qualquer um dos três retratos — a decisão de "trocar de ativa"
  /// vs "ciclar postura da ativa" é de `CreaturesRogueGame.onTapCompanionSlot`,
  /// não da Hud nem do retrato.
  final void Function(int slot) onTapCompanionSlot;
  // Sprites
  late final Sprite heartSprite;
  late final Sprite heartHalfSprite;
  late final Sprite heartEmptySprite;
  late final Sprite shieldSprite;
  late final Sprite moedaSprite;

  final Paint emptyHeartPaint = Paint()
    ..colorFilter = const ColorFilter.mode(Palette.preto, BlendMode.srcATop)
    ..filterQuality = FilterQuality.none;

  final Paint paint = Paint()..filterQuality = FilterQuality.none;

  late final TextPaint textPaint;

  final Vector2 heartSize = Vector2(16, 16);
  final Vector2 bombIconSize = Vector2(16, 16);
  final double spacing = -11.0;

  /// Lado dos indicadores de cooldown. 16 é o tamanho nativo dos sprites
  /// (`ui/ataque.png` e `ui/defesa.png`), então a escala fica 1:1 e o pixel art
  /// não ganha artefato de reamostragem.
  static const double _iconeCooldownLado = 16;

  //static final Vector2 _shieldBarSize = Vector2(3, 3);

  /// Largura máxima das barras de vida/escudo, em px da resolução fixa (192).
  /// Sem teto, cada `hpUp` somava 3px e a barra saía da tela depois de poucos
  /// upgrades. Passando desse ponto a barra para de crescer e cada ponto de
  // vida passa a valer menos pixel.
  // const double _barraLarguraMax = 60.0;

  /// Quantos px vale um ponto, dado o total [maxValor] da barra.
  // double _pxPorPonto(double maxValor) => maxValor <= 0
  //     ? 0
  //    : math.min(_shieldBarSize.x, _barraLarguraMax / maxValor);

  late final TextPaint coinTextPaint;

  /// Barra de evolução (ver PIVOT_EVOLUCAO) — linha preta de fundo (o
  /// "comprimento alvo") com um preenchimento verde por cima que cresce
  /// conforme `player.xp`. Fica entre os corações e o ícone de moeda.
  final Paint _evoTrackPaint = Paint()..color = Palette.preto;
  final Paint _evoFundoPaint = Paint()..color = Palette.branco;
  final Paint _evoFillPaint = Paint()..color = Palette.jade;
  static const double _evoBarWidth = 32;
  static const double _evoBarY = 15;
  static const double _evoBarHeight = 2;
  // final Paint _shieldMoldura = Paint()..color = Palette.preto;
  // final Paint _shieldFundo = Paint()..color = Palette.preto;
  // final Paint _shieldPreenchimento = Paint()..color = Palette.azul;
  // final Paint _hpPreenchimento = Paint()..color = Palette.vermelho;

  Hud({
    required this.player,
    required this.companionCreatureAt,
    required this.companionPocketFractionAt,
    required this.isCompanionAtivo,
    required this.onTapCompanionSlot,
  }) : super(position: Vector2(0, 0));

  @override
  Future<void> onLoad() async {
    super.onLoad();
    final ui.Image moedaImg = await PaletteSwapper.createSwappedImage(
      imagePath: 'ui/moeda.png',
      lightGrayReplacement: Palette.amarelo,
      darkGrayReplacement: Palette.laranja,
    );
    moedaSprite = Sprite(moedaImg);

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

    final ui.Image shieldImg = await PaletteSwapper.createSwappedImage(
      imagePath: 'ui/heart.png',
      lightGrayReplacement: Palette.azul,
      darkGrayReplacement: Palette.azulEsc,
    );

    heartSprite = Sprite(heartImg);
    heartHalfSprite = Sprite(heartHalfImg);
    heartEmptySprite = Sprite(heartEmptyImg);
    shieldSprite = Sprite(shieldImg);

    //bombSprite = Sprite(bombImg);

    // Indicadores de cooldown, logo abaixo das barras de vida/escudo. Ficam
    // como filhos e não dentro do render() da Hud pra cada um cuidar do seu
    // próprio sprite e do seu carregamento assíncrono.
    await addAll([
      // Duas habilidades diretas do jogador — voltou ao controle direto
      // (PIVOT_CONTROLE_DIRETO.md), então os dois indicadores lêem o
      // `Player` de novo, não mais uma criatura autônoma.
      /*  AbilityCooldownIndicator(
        tipo: () => player.creatureData.ability1.tipo,
        cooldownFraction: () => player.ability1CooldownFraction,
        lado: _iconeCooldownLado,
        position: Vector2(0, 14),
      ),
      AbilityCooldownIndicator(
        tipo: () => player.creatureData.ability2.tipo,
        cooldownFraction: () => player.ability2CooldownFraction,
        lado: _iconeCooldownLado,
        position: Vector2(_iconeCooldownLado + 2, 14),
      ),
      */
      // Três retratos, um por slot do grupo — mesmo cinza que o indicador de
      // cooldown usa, agora mostrando quanto falta curar no banco, mais o
      // destaque de quem é a ativa (ver `CompanionPortraitIndicator`). Abaixo
      // do ícone+contagem de moedas (`render`, y 22-38) pra não sobrepor.
      for (int slot = 0; slot < 3; slot++)
        CompanionPortraitIndicator(
          creatureData: () => companionCreatureAt(slot),
          pocketFraction: () => companionPocketFractionAt(slot),
          isAtiva: () => isCompanionAtivo(slot),
          onTap: () => onTapCompanionSlot(slot),
          lado: _iconeCooldownLado,
          position: Vector2(2, 34 + (_iconeCooldownLado + 2) * slot),
        ),
    ]);

    textPaint = TextPaint(
      style: const TextStyle(
        fontFamily: 'pixelFont',
        color: Palette.branco,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 1),
        ],
      ),
    );

    coinTextPaint = TextPaint(
      style: const TextStyle(
        fontFamily: 'pixelFont',
        color: Palette.branco,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Palette.preto, offset: Offset(1, 1)),
          Shadow(color: Palette.preto, offset: Offset(-1, -1)),
          Shadow(color: Palette.preto, offset: Offset(1, -1)),
          Shadow(color: Palette.preto, offset: Offset(-1, 1)),
          Shadow(color: Palette.preto, offset: Offset(0, 1)),
          Shadow(color: Palette.preto, offset: Offset(0, -1)),
          Shadow(color: Palette.preto, offset: Offset(1, 0)),
          Shadow(color: Palette.preto, offset: Offset(-1, 0)),
        ],
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    /*
    final pxHp = _pxPorPonto(player.maxHealth);
    canvas.drawRect(Rect.fromLTWH(-1, 1 - 1, pxHp * player.maxHealth + 2, _shieldBarSize.y + 2), _shieldMoldura);
    canvas.drawRect(Rect.fromLTWH(0, 1, pxHp * player.maxHealth, _shieldBarSize.y), _shieldFundo);
    canvas.drawRect(Rect.fromLTWH(0, 1, pxHp * player.currentHealth, _shieldBarSize.y), _hpPreenchimento);


    final pxEscudo = _pxPorPonto(player.shieldMax);
    canvas.drawRect(Rect.fromLTWH(pxHp * player.maxHealth + 0, 0, pxEscudo * player.shieldMax + 2, _shieldBarSize.y + 2), _shieldMoldura);
    canvas.drawRect(Rect.fromLTWH(pxHp * player.maxHealth + 1, 1, pxEscudo * player.shieldMax, _shieldBarSize.y), _shieldFundo);
    canvas.drawRect(Rect.fromLTWH(pxHp * player.maxHealth + 1, 1, pxEscudo * player.shield, _shieldBarSize.y), _shieldPreenchimento);
*/
    // --- BARRA DE EVOLUÇÃO --- Só desenha pra quem tem forma evoluída
    // desenhada (`evoluir != null`) — as outras criaturas não têm o que
    // progredir ainda, então não ganham uma barra sempre vazia.
    if (player.creatureData.evoluir != null) {
      canvas.drawRect(
        Rect.fromLTWH(2, _evoBarY-1, _evoBarWidth+1, _evoBarHeight+2),
        _evoTrackPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(2, _evoBarY-1, _evoBarWidth, _evoBarHeight+1),
        _evoFundoPaint,
      );
      
      canvas.drawRect(
        Rect.fromLTWH(
          2,
          _evoBarY,
          _evoBarWidth * player.xpFracao,
          _evoBarHeight,
        ),
        _evoFillPaint,
      );
    }

    moedaSprite.render(
      canvas,
      position: Vector2(0, 18),
      size: bombIconSize,
      overridePaint: paint,
    );
    coinTextPaint.render(canvas, ':${player.coins}', Vector2(16, 19));

    // --- LÓGICA DO MEIO-CORAÇÃO ---
    // Quantos corações INICIAIS (capacidade total) o jogador tem na tela?
    // Como a escala do player é dobrada (maxHealth = 6), dividimos por 2 (3 corações na tela).
    int totalHeartsOnScreen = (player.maxHealth / 2).floor();

    // Quantos corações visualmente inteiros ele tem? (ex: vida 5 / 2 = 2 inteiros)
    int fullHearts = (player.currentHealth / 2).floor();

    // Tem algum resto? (ex: vida 5 % 2 = 1). Se sim, tem um meio-coração solto!
    bool hasHalfHeart = (player.currentHealth % 2) != 0;

    for (int i = 0; i < totalHeartsOnScreen; i++) {
      final xPosition =
          (i * (heartSize.x + spacing) - ((heartSize.x + spacing) + 2)) + 3;

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
        overridePaint: paint,
      );
    }

    // --- BARRA DE ESCUDO PASSIVO (defesa) ---
    for (int i = 0; i < player.shield; i++) {
      double shieldX =
          3 +
          player.maxHealth / 2 * (heartSize.x + spacing) +
          (i * (heartSize.x + spacing)) -
          ((heartSize.x + spacing) + 2); // Posição X após os corações
      final double shieldY = 0; //heartSize.y + 1;
      //final fracao = (player.shield / player.shieldMax).clamp(0.0, 1.0);

      shieldSprite.render(
        canvas,
        position: Vector2(shieldX, shieldY),
        size: heartSize,
        overridePaint: paint,
      );
      //canvas.drawRect(Rect.fromLTWH(shieldX-1, shieldY - 1, _shieldBarSize.x + 2, _shieldBarSize.y + 2), _shieldMoldura);
      //canvas.drawRect(Rect.fromLTWH(shieldX, shieldY, _shieldBarSize.x, _shieldBarSize.y), _shieldFundo);
      //canvas.drawRect(Rect.fromLTWH(shieldX, shieldY, _shieldBarSize.x * fracao, _shieldBarSize.y), _shieldPreenchimento);
    }

    //double bombY = heartSize.y + 2;
    //bombSprite.render(canvas, position: Vector2(0, bombY), size: bombIconSize, overridePaint: paint);
    //textPaint.render(canvas, ':${player.bombsAmount}', Vector2(bombIconSize.x + 0, bombY+1));
  }
}
