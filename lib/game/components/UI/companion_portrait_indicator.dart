import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';

/// Retrato de UM slot do grupo (0/1/2) na Hud — sprite da criatura daquele
/// slot, com o mesmo indicador cinza de cooldown que `AbilityCooldownIndicator`
/// usa, agora mostrando quanto falta de vida no banco (ver
/// `CreaturesRogueGame.companionPocketFraction`). Sem cura passiva, esse
/// cinza é um retrato estático da vida com que a criatura saiu de campo, não
/// uma barra enchendo com o tempo — só muda quando ela entra/sai do banco de
/// novo. Existe mesmo com o slot no banco — é o único lugar que mostra
/// status dele nesse intervalo.
///
/// `creatureData` é uma função, não um valor fixo: os slots 1 e 2 nascem
/// vazios (`null`) e só ganham criatura quando a criatura selvagem da sala
/// da escada preencher (PIVOT_CONTROLE_DIRETO.md §5) — o retrato precisa
/// notar essa mudança em pleno jogo e carregar o sprite na hora, não só uma
/// vez no `onLoad` (que já teria passado).
///
/// Também é o controle de troca de ativa
/// (`CreaturesRogueGame.onTapCompanionSlot`): tocar num retrato com vida
/// troca qual é a ativa; tocar o já ativo, um vazio, ou um já derrotado
/// (vida 0), não faz nada — este componente só avisa "fui tocado".
class CompanionPortraitIndicator extends PositionComponent with TapCallbacks {
  final CreatureData? Function() creatureData;

  /// 0 = ativa (ou vida cheia no banco), 1 = acabou de entrar no banco com a
  /// vida zerada. Mesma convenção de `AbilityCooldownIndicator.cooldownFraction`.
  final double Function() pocketFraction;

  /// Se este é o slot que o jogador está controlando agora — desenha um
  /// contorno mais claro pra diferenciar dos outros dois.
  final bool Function() isAtiva;

  final VoidCallback onTap;

  Sprite? _sprite;
  CreatureData? _spriteDe;
  bool _carregandoSprite = false;

  final Paint _spritePaint = Paint()..filterQuality = FilterQuality.none;
  final Paint _cooldownPaint = Paint()..color = Palette.vermelho.withAlpha(220);
  final Paint _fundoVazio = Paint()..color = Palette.cinzaEsc.withAlpha(80);
  final Paint _fundo = Paint()..color = Palette.branco;
  final Paint _bordaAtiva = Paint()
    ..color = Palette.preto
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint _bordaInativa = Paint()
    ..color = Palette.preto
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  CompanionPortraitIndicator({
    required this.creatureData,
    required this.pocketFraction,
    required this.isAtiva,
    required this.onTap,
    required double lado,
    super.position,
  }) : super(size: Vector2.all(lado));

  @override
  void onTapUp(TapUpEvent event) => onTap();

  /// Sem `onLoad`: com `creatureData` podendo virar `null` (ou trocar, no dia
  /// em que a fase 6 encher um slot vazio em pleno jogo), o carregamento do
  /// sprite precisa reagir a mudança, não rodar uma vez só no começo.
  @override
  void update(double dt) {
    super.update(dt);
    final atual = creatureData();
    if (identical(atual, _spriteDe) || _carregandoSprite) return;

    _spriteDe = atual;
    if (atual == null) {
      _sprite = null;
      return;
    }

    _carregandoSprite = true;
    PaletteSwapper.createSwappedImage(
      imagePath: atual.spritePath,
      lightGrayReplacement: atual.corClara,
      darkGrayReplacement: atual.corEscura,
    ).then((ui.Image img) {
      _sprite = Sprite(img);
      _carregandoSprite = false;
    });
  }

  @override
  void render(Canvas canvas) {
    if(_sprite == null)return;
    
    final quadro = Rect.fromLTWH(0, 0, size.x, size.y);

    canvas.drawRect(quadro, _fundo);

    // Cresce de baixo pra cima conforme a vida salva (pedido do usuário) — o
    // inverso de `fraction` (que É quanto falta de vida), então a barra usa
    // `progresso` (quanto de vida sobrou) pra altura. Sem cura passiva, isso
    // fica parado enquanto a criatura está no banco: só muda de novo quando
    // ela volta a campo (vida cheia) ou desmaia lá fora (vida 0 — o cinza
    // cobre o retrato inteiro).
    final fraction = pocketFraction().clamp(0.0, 1.0);
    if (fraction > 0) {
      final progresso = 1 - fraction;
      final altura = size.y * progresso;
      canvas.drawRect(
        Rect.fromLTWH(0, size.y - altura, size.x, altura),
        _cooldownPaint,
      );
    }

    final sprite = _sprite;
    if (sprite != null) {
      sprite.render(canvas, size: size, overridePaint: _spritePaint);
    } else {
      canvas.drawRect(quadro, _fundoVazio);
    }

    canvas.drawRect(quadro, isAtiva() ? _bordaAtiva : _bordaInativa);
  }
}
