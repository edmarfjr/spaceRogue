import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Anel colorido desenhado no chão, em volta de um inimigo campeão — é ele
/// que diz QUAL campeão é aquele (ver `CampeaoTipo`).
///
/// No chão e não no corpo, de propósito. A paleta do corpo de um inimigo já
/// carrega informação: `corClara`/`corEscura` vêm do `CreatureData` e dizem o
/// ELEMENTO da criatura, que é o que decide vantagem de dano
/// (`typeMultiplier`, 2x ou 0,5x). Pintar o corpo de amarelo pra dizer "este é
/// veloz" apagaria a informação que o jogador usa pra escolher com qual
/// criatura enfrentar. O anel é um canal novo, que não disputa com aquele.
///
/// Pulsa devagar em vez de ficar parado: um anel estático some no meio do
/// cenário quando o inimigo está sobre grama alta ou perto de outro bicho, e
/// movimento é o que o olho pega primeiro numa tela de 160x144.
class AuraCampeao extends PositionComponent {
  AuraCampeao({
    required this.cor,
    required this.raioBase,
    required Vector2 position,
  }) : super(
         position: position,
         anchor: Anchor.center,
         // Atrás do sprite, junto da sombra: o anel emoldura o inimigo em vez
         // de riscar por cima dele.
         priority: -1,
       );

  final Color cor;

  /// Metade da largura da hitbox do inimigo, igual à sombra — assim o anel
  /// acompanha o corpo de qualquer criatura sem número escolhido a dedo.
  final double raioBase;

  /// Quanto o raio varia no pulso, como fração de [raioBase].
  static const double _amplitude = 0.15;

  /// Segundos de um ciclo completo do pulso.
  static const double _periodo = 1.2;

  double _tempo = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _tempo += dt;
  }

  @override
  void render(Canvas canvas) {
    final fase = (_tempo / _periodo) * 2 * math.pi;
    final raio = raioBase * (1 + _amplitude * math.sin(fase));

    final aura = Paint()
      ..color = cor.withAlpha(100)
      //..style = PaintingStyle.stroke
     // ..strokeWidth = 1.5
      ..isAntiAlias = false;

    final traco = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = false;

    // Achatado no eixo Y pela mesma razão da sombra: a câmera é topdown de
    // três quartos, e um círculo redondo no chão leria como esfera em pé.
    canvas.save();
    canvas.scale(1.0, 0.75);
    canvas.drawCircle(Offset.zero, raio, aura);
    canvas.drawCircle(Offset.zero, raio, traco);
    canvas.restore();
  }
}
