import 'dart:ui' as ui;

import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Ícones de condição exibidos acima do sprite do inimigo. Só os ícones de
/// condições ativas aparecem, lado a lado, sem se sobrepor.
///
/// São cinco condições possíveis num inimigo de 16px dentro de uma sala de
/// 192px, então o ícone é desenhado em 8px — metade exata dos 16px nativos do
/// sprite, escala limpa sem artefato de reamostragem. Com os cinco ativos a
/// fileira ocupa 44px; a 16px ocuparia 84px, quase metade da largura da sala.
class ConditionIcons extends PositionComponent {
  static const double _iconSize = 8.0;
  static const double _gap = 1.0;

  bool stunAtivo = false;
  bool venenoAtivo = false;
  bool queimaduraAtivo = false;
  bool lentidaoAtivo = false;
  bool cegoAtivo = false;

  /// Ordem fixa de desenho, casada índice a índice com [_estados].
  final List<SpriteComponent> _icones = [];

  List<bool> get _estados =>
      [stunAtivo, venenoAtivo, queimaduraAtivo, lentidaoAtivo, cegoAtivo];

  ConditionIcons() : super(anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    final definicoes = <(String, Color, Color)>[
      ('effects/stun.png', Palette.cinza, Palette.laranja),      // stun
      ('effects/poison.png', Palette.verde, Palette.amarelo),    // veneno
      ('effects/fogo.png', Palette.laranja, Palette.vermelho), // queimadura
      ('effects/lento.png', Palette.azul, Palette.indigo),        // lentidão
      ('effects/cego.png', Palette.cinzaEsc, Palette.roxoEsc),   // cegueira
    ];

    for (final (caminho, clara, escura) in definicoes) {
      final ui.Image img = await PaletteSwapper.createSwappedImage(
        imagePath: caminho,
        lightGrayReplacement: clara,
        darkGrayReplacement: escura,
        whiteReplacement: Palette.branco,
      );
      final icone = SpriteComponent(
        sprite: Sprite(img),
        size: Vector2.all(_iconSize),
        anchor: Anchor.bottomCenter,
        paint: Paint()..filterQuality = FilterQuality.none,
      );
      icone.setOpacity(0.0);
      _icones.add(icone);
      add(icone);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_icones.isEmpty) return; // onLoad ainda não terminou

    final estados = _estados;
    final ativos = estados.where((e) => e).length;
    if (ativos == 0) {
      for (final icone in _icones) {
        icone.setOpacity(0.0);
      }
      return;
    }

    final largura = ativos * _iconSize + (ativos - 1) * _gap;
    double x = -largura / 2 + _iconSize / 2;

    for (int i = 0; i < _icones.length; i++) {
      final visivel = estados[i];
      _icones[i].setOpacity(visivel ? 1.0 : 0.0);
      if (visivel) {
        _icones[i].position = Vector2(x, 0);
        x += _iconSize + _gap;
      }
    }
  }
}
