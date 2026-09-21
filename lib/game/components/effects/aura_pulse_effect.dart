import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:creatures_rogue/game/components/utils/y_sort.dart';

/// Onda circular que se abre até [raio] e desaparece, desenhada no chão em
/// volta de quem a soltou. Serve pra mostrar o ALCANCE de um efeito em área
/// que, sem isso, acerta sem dizer onde começa e onde acaba.
///
/// Pulso a cada tique, e não um anel permanente: a sala tem 160x144 e o
/// alcance de uma aura passa fácil de um terço da largura da tela. Um círculo
/// ligado o tempo todo desse tamanho vira ruído em cima do que importa (os
/// inimigos), enquanto o pulso aparece justo quando o dano sai — então ele
/// informa o alcance E a cadência de uma vez.
///
/// Desenha UMA unidade atrás dos pés de quem a soltou (mesma conta do
/// `ChamasEffect`), pra passar por baixo dos atores em vez de riscar por cima
/// deles. A prioridade é fixada no nascimento: o efeito dura frações de
/// segundo e ninguém se move o bastante nesse tempo pra a ordem trocar.
class AuraPulseEffect extends PositionComponent {
  AuraPulseEffect({
    required Vector2 position,
    required this.raio,
    required this.cor1,
    required this.cor2,
    this.duracao = 0.3,
  }) : super(position: position.clone()) {
    priority = ySortPriority(position.y) - 1;
  }

  /// Raio final do anel — o alcance real do efeito, não um número visual.
  final double raio;

  final Color cor1;
  final Color cor2;
  final double duracao;

  double _tempo = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _tempo += dt;
    if (_tempo >= duracao) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_tempo / duracao).clamp(0.0, 1.0);
    // Abre desde o corpo até o alcance cheio. O anel chega no raio final no
    // último quadro, que é onde o jogador precisa ler a borda.
    final atual = raio * t;
    if (atual <= 0) return;

    final traco = Paint()
      ..color = cor1
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..filterQuality = FilterQuality.none;

    // Segunda volta por fora, mesma receita do `CompanionReviveEffect`: sem
    // ela o anel se perde no chão claro de algumas salas.
    final contorno = Paint()
      ..color = cor2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..filterQuality = FilterQuality.none;

    canvas.drawCircle(Offset.zero, atual, traco);
    canvas.drawCircle(Offset.zero, atual + 1, contorno);
  }
}
