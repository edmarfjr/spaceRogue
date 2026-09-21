import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/utils/y_sort.dart';

class _Particula {
  _Particula(this.pos, this.vel, this.vida);

  final Vector2 pos;
  final Vector2 vel;

  /// Segundos de vida TOTAL, fixado no nascimento — o tamanho e a cor saem do
  /// quanto já passou dela.
  final double vida;
  double idade = 0.0;

  double get fracao => (idade / vida).clamp(0.0, 1.0);
}

/// Chamas saindo do corpo do jogador enquanto ele estiver causando dano de
/// contato (ver `Player.danoDeContato`) — o sinal visual de que a Roda de Fogo
/// atingiu a velocidade máxima.
///
/// Amarrado a `danoDeContato`, e não à Roda de Fogo: o gatilho é "o corpo está
/// quente", então qualquer criatura futura com dano de contato ganha o efeito
/// sem mexer aqui. A passiva só liga e desliga o número; o visual é daqui.
///
/// Vive no MUNDO, não como filho do jogador. Filho seguiria o pai, e as
/// partículas arrastariam junto — elas precisam ficar onde nasceram pra
/// desenhar um rastro. Por isso o componente lê a posição do jogador a cada
/// quadro em vez de herdar transformação.
///
/// Criado uma única vez, no `onLoad` do jogador: sem emissão quando
/// `danoDeContato` é zero, ele custa um `if` por quadro e nada mais. Criar e
/// destruir conforme a criatura muda daria duplicata na troca.
class ChamasEffect extends PositionComponent {
  /// Onde as partículas nascem — a posição do jogador, lida por quadro.
  final Vector2 Function() origem;

  /// Enquanto true, emite. É `danoDeContato > 0` na prática.
  final bool Function() ativo;

  /// Prioridade de quem estamos acompanhando, pra desenhar UMA unidade atrás
  /// dele: as chamas lambem em volta sem cobrir o sprite, que continua
  /// legível.
  final double Function() alturaDoPe;

  static const int _particulasPorSegundo = 45;

  /// Teto de partículas vivas. Com 45/s e 0,4s de vida o normal fica perto de
  /// 18 — o teto só existe pra um travamento de quadro não virar uma lista
  /// gigante de uma vez.
  static const int _maxParticulas = 60;

  static const double _vidaMin = 0.25;
  static const double _vidaMax = 0.45;
  static const double _raioMax = 3;

  /// Subida das chamas, em px/s. Negativo = pra cima.
  static const double _velY = -26.0;
  static const double _espalhamentoX = 14.0;

  final List<_Particula> _particulas = [];
  final Random _rng = Random();
  double _acumulado = 0.0;

  final Paint _paint = Paint()..filterQuality = FilterQuality.none;

  ChamasEffect({
    required this.origem,
    required this.ativo,
    required this.alturaDoPe,
  });

  @override
  void update(double dt) {
    super.update(dt);

    priority = ySortPriority(alturaDoPe()) - 1;

    if (ativo()) {
      // Acumulador em vez de "uma por quadro": a taxa de emissão fica a mesma
      // a 30 ou a 60fps.
      _acumulado += dt * _particulasPorSegundo;
      while (_acumulado >= 1 && _particulas.length < _maxParticulas) {
        _acumulado -= 1;
        _emitir();
      }
      if (_particulas.length >= _maxParticulas) _acumulado = 0.0;
    } else {
      _acumulado = 0.0;
    }

    for (final p in _particulas) {
      p.idade += dt;
      p.pos.add(p.vel * dt);
    }
    _particulas.removeWhere((p) => p.idade >= p.vida);
  }

  void _emitir() {
    final o = origem();
    _particulas.add(
      _Particula(
        // Nasce espalhada na largura do corpo e um pouco abaixo do centro,
        // pra chama parecer sair de baixo e subir pelo sprite.
        Vector2(
          o.x + (_rng.nextDouble() - 0.5) * _espalhamentoX,
          o.y + 4 - _rng.nextDouble() * 4,
        ),
        Vector2(
          (_rng.nextDouble() - 0.5) * 12,
          _velY * (0.7 + _rng.nextDouble() * 0.6),
        ),
        _vidaMin + _rng.nextDouble() * (_vidaMax - _vidaMin),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    // Sem `super.render`: não há sprite, só as partículas.
    for (final p in _particulas) {
      final t = p.fracao;

      // Gradiente de fogo pela idade: nasce clara no núcleo e morre vermelha,
      // que é como fogo real esfria conforme sobe.
      final cor = t < 0.35
          ? Palette.pumpkin
          : (t < 0.3 ? Palette.cinzaEsc : Palette.vermelho);

      _paint.color = cor;//.withAlpha(((1 - t) * 255).round().clamp(0, 255));
      _paint.filterQuality = FilterQuality.none;
      canvas.drawCircle(
        Offset(p.pos.x - position.x, p.pos.y - position.y),
        _raioMax * (1 - t),
        _paint,
      );
    }
  }
}
