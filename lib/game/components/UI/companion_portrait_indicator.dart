import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/companion.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';

/// Retrato de UM slot do grupo (0/1/2 — PIVOT_TREINADOR.md, fase 5b) na Hud —
/// sprite da criatura daquele slot, com o mesmo indicador cinza de cooldown
/// que `AbilityCooldownIndicator` usa, mostrando quanto falta pro companion
/// voltar de um desmaio (ver `CreaturesRogueGame.companionReviveDuration`).
/// Existe mesmo com o companion morto — é o único lugar que mostra status
/// dele nesse intervalo, já que o componente em si some do mundo enquanto o
/// timer conta.
///
/// `creatureData` é uma função, não um valor fixo: os slots 1 e 2 nascem
/// vazios (`null`) e só ganham criatura quando a fase 6 (captura) existir —
/// o retrato precisa notar essa mudança em pleno jogo e carregar o sprite na
/// hora, não só uma vez no `onLoad` (que já teria passado).
///
/// Também é o controle de postura E de troca de ativa (PIVOT_TREINADOR.md
/// §2.1.1): tocar no retrato JÁ ativo cicla a postura dele; tocar em outro
/// troca qual é a ativa. A decisão de qual das duas ações o toque significa
/// é de fora (`CreaturesRogueGame.onTapCompanionSlot`) — este componente só
/// avisa "fui tocado".
class CompanionPortraitIndicator extends PositionComponent with TapCallbacks {
  final CreatureData? Function() creatureData;

  /// 0 = companion vivo (ou pronto de novo), 1 = acabou de desmaiar. Mesma
  /// convenção de `AbilityCooldownIndicator.cooldownFraction`.
  final double Function() reviveFraction;

  /// Postura atual, lida a cada frame — `null` com o slot vazio ou o
  /// companion desmaiado (nada pra ciclar).
  final CompanionPostura? Function() posturaAtual;

  /// Se este é o slot que recebe o override dos botões agora — desenha um
  /// contorno mais claro pra diferenciar dos outros dois.
  final bool Function() isAtiva;

  final VoidCallback onTap;

  Sprite? _sprite;
  CreatureData? _spriteDe;
  bool _carregandoSprite = false;

  final Paint _spritePaint = Paint()..filterQuality = FilterQuality.none;
  final Paint _cooldownPaint = Paint()..color = Palette.cinzaEsc.withAlpha(220);
  final Paint _posturaAgressivo = Paint()..color = Palette.vermelho;
  final Paint _posturaSegurar = Paint()..color = Palette.azul;
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
    required this.reviveFraction,
    required this.posturaAtual,
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
    final quadro = Rect.fromLTWH(0, 0, size.x, size.y);

    canvas.drawRect(quadro, _fundo);

    final sprite = _sprite;
    if (sprite != null) {
      sprite.render(canvas, size: size, overridePaint: _spritePaint);
    } else {
      canvas.drawRect(quadro, _fundoVazio);
    }

    canvas.drawRect(quadro, isAtiva() ? _bordaAtiva : _bordaInativa);

    final fraction = reviveFraction().clamp(0.0, 1.0);
    if (fraction > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, size.y * (1 - fraction), size.x, size.y * fraction),
        _cooldownPaint,
      );
    }

    // Marcador de postura: um quadradinho no canto, só quando não é `seguir`
    // (o default não precisa de indicador — vermelho = agressivo, azul =
    // segurar, mesmas cores que a barra de vida/escudo já usa pra HP/escudo).
    final lado = size.x * 0.3;
    switch (posturaAtual()) {
      case CompanionPostura.agressivo:
        canvas.drawRect(Rect.fromLTWH(size.x - lado, 0, lado, lado), _posturaAgressivo);
      case CompanionPostura.segurar:
        canvas.drawRect(Rect.fromLTWH(size.x - lado, 0, lado, lado), _posturaSegurar);
      case CompanionPostura.seguir:
      case null:
        break;
    }
  }
}
