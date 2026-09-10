import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';

/// Cores da "casca" da tela de jogo — tudo que não é o mundo desenhado pela
/// câmera de resolução fixa (160x144). Hoje só a área lateral onde ficam
/// joystick e botões de habilidade (letterbox/pillarbox fora do mapa), mas é
/// o ponto único pra qualquer cor de UI que precise ser trocada depois sem
/// caçar hex espalhado pelo código.
class UiTheme {
  UiTheme._();

  /// Preenche a tela inteira atrás do mundo do jogo — visível nas margens
  /// laterais onde os controles ficam, já que o mapa só ocupa a resolução
  /// fixa da câmera. Cinza claro = plástico do Game Boy original.
  static const Color screenBackground = Palette.cinza;

  /// Moldura escura ao redor da área jogável — o "vão" preto que cerca a
  /// tela de LCD no Game Boy de verdade, separando o plástico do shell do
  /// conteúdo da tela.
  static const Color screenBezel = Palette.preto;

  /// Cores da cápsula do botão de pause (estilo START/SELECT do Game Boy).
  static const Color pauseCapsuleCor1 = Palette.indigo;
  static const Color pauseCapsuleCor2 = Palette.azulEsc;

  /// Cores do botão de ação e (estilo A/B do Game Boy).
  static const Color actionButtonCor1 = Palette.burgundy;
  static const Color actionButtonCor2 = Palette.roxoEsc;

  /// Cores do dpad.
  static const Color dpadCor1 = Palette.cinzaEsc;
  static const Color dpadCor2 = Palette.azulEsc;

  /// Cores do apad.
  static const Color apadCor1 = Palette.burgundy;
  static const Color apadCor2 = Palette.roxoEsc;
  
}
