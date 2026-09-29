import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/utils/y_sort.dart';

/// A corrente desenhada entre o jogador e a bola da `Coleira`.
///
/// Componente próprio, irmão da bola no mundo, e não filho dela: filho herda a
/// transformação do pai, e a bola gira — a corrente sairia rodopiando junto
/// com ela. Aqui a posição fica em (0,0) e o `render` desenha direto em
/// coordenadas de mundo, então as duas pontas são lidas sem conversão
/// nenhuma.
///
/// Sem a corrente a bola lê como um satélite solto; é o fio que diz que aquilo
/// está PRESO em você, que é o que justifica o custo de velocidade do item.
class CorrenteVisual extends PositionComponent {
  CorrenteVisual({required this.dono, required this.bola});

  final PositionComponent dono;
  final PositionComponent bola;

  /// Quantos pedaços de corrente entre as duas pontas. Os elos das pontas não
  /// são desenhados — eles cairiam por baixo do corpo do jogador e da bola.
  static const int elos = 6;

  static const double ladoElo = 1.0;

  final Paint _tinta = Paint()..color = Palette.cinzaEsc..isAntiAlias=false..style=PaintingStyle.stroke..strokeWidth=1;
  final Paint _tintaEscura = Paint()..color = Palette.indigo..isAntiAlias=false..style=PaintingStyle.stroke..strokeWidth=1;

  @override
  void update(double dt) {
    super.update(dt);
    // A corrente morre com a bola. Sem isto ela ficaria pendurada num
    // componente desmontado depois de uma troca de andar ou do fim da run.
    if (!bola.isMounted) {
      removeFromParent();
      return;
    }
    // Mesma faixa de profundidade do dono, pra corrente não passar por cima
    // de quem está à frente dele na sala.
    priority = ySortPriority(dono.position.y);
  }

  @override
  void render(Canvas canvas) {
    final a = dono.absolutePosition;
    final b = bola.absolutePosition;

    for (var i = 1; i < elos-1; i++) {
      final t = i / elos;
      final p = a + (b - a) * t;
      // Elos alternados em duas tintas: numa tela de 160x144 uma linha de cor
      // única vira um borrão, e a alternância é o que dá a leitura de "isto é
      // feito de partes".
      /*canvas.drawRect(
        Rect.fromCenter(
          center: Offset(p.x, p.y),
          width: ladoElo,
          height: ladoElo,
        ),
        i.isEven ? _tinta : _tintaEscura,
      );
      */
      canvas.drawCircle(
        Offset(p.x, p.y),
        ladoElo,
        i.isEven ? _tinta : _tintaEscura,
      );
    }
  }
}
