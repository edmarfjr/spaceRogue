import 'dart:math';
import 'package:flame/components.dart';

/// Estilo de animação de movimento de uma criatura. Cada criatura (jogável
/// ou inimiga) usa exatamente um destes, aplicado ao componente `visual`
/// por transformação (ângulo/escala/posição) — não por troca de sprite,
/// já que o sprite em si é estático.
enum MovementAnimation { caminhada, saltitar, arrastar, flutuar }

/// Aplica a animação de movimento a um `SpriteComponent`, mexendo só em
/// `angle`, `scale` e um deslocamento em cima da posição de repouso
/// informada. Guarda sua própria fase (`_time`), então cada ator precisa
/// da sua própria instância — não dá pra compartilhar entre criaturas.
///
/// Parada, toda criatura respira (um pulso sutil de escala) — é o idle
/// padrão. `flutuar` é a exceção: parado, ele flutua pra cima e pra baixo
/// em vez de respirar; andando, inclina para o lado do movimento.
///
/// O flip horizontal (virar o sprite pra esquerda/direita) é feito por fora,
/// via `flipHorizontallyAroundCenter()`, e é codificado como o sinal de
/// `scale.x` (negativo = espelhado). Toda escrita em `scale.x` aqui dentro
/// preserva esse sinal — senão cada frame desfaria o flip sem querer.
class MovementAnimator {
  final MovementAnimation type;
  double _time = 0.0;

  MovementAnimator(this.type);

  static const double _walkPeriod = 0.35;
  static const double _walkAmplitude = 0.18;

  static const double _hopPeriod = 0.4;
  static const double _hopAmplitude = 3.0;

  static const double _crawlPeriod = 0.4;
  static const double _crawlAmplitude = 0.22;

  static const double _breathPeriod = 0.9;
  static const double _breathAmplitude = 0.06;

  static const double _floatIdlePeriod = 1.6;
  static const double _floatIdleAmplitude = 2.0;
  static const double _floatBankAmount = 0.3;

  /// [horizontalDir] é a componente X da direção de movimento, normalizada
  /// entre -1 (esquerda) e 1 (direita). Só importa pro estilo `flutuar`.
  void update({
    required SpriteComponent visual,
    required Vector2 basePosition,
    required bool isMoving,
    required double horizontalDir,
    required double dt,
  }) {
    _time += dt;
    final flip = visual.scale.x.isNegative ? -1.0 : 1.0;

    switch (type) {
      case MovementAnimation.caminhada:
        if (isMoving) {
          visual.angle = sin(_time * 2 * pi / _walkPeriod) * _walkAmplitude;
          visual.scale = Vector2(flip, 1.0);
        } else {
          visual.angle = 0.0;
          _breathe(visual, flip);
        }
        break;

      case MovementAnimation.saltitar:
        if (isMoving) {
          final bounce = sin(_time * 2 * pi / _hopPeriod).abs();
          visual.position.y = basePosition.y - bounce * _hopAmplitude;
          visual.scale = Vector2(flip, 1.0);
        } else {
          visual.position.y = basePosition.y;
          _breathe(visual, flip);
        }
        break;

      case MovementAnimation.arrastar:
        if (isMoving) {
          final wave = sin(_time * 2 * pi / _crawlPeriod);
          visual.scale = Vector2(
            (1.0 - wave * _crawlAmplitude * 0.5) * flip,
            1.0 + wave * _crawlAmplitude,
          );
        } else {
          _breathe(visual, flip);
        }
        break;

      case MovementAnimation.flutuar:
        // Nunca mexe em scale — o flip de fora chega intacto sozinho.
        if (isMoving) {
          visual.position.y = basePosition.y;
          visual.angle = horizontalDir.clamp(-1.0, 1.0) * _floatBankAmount;
        } else {
          visual.angle = 0.0;
          final bob = sin(_time * 2 * pi / _floatIdlePeriod);
          visual.position.y = basePosition.y + bob * _floatIdleAmplitude;
        }
        break;
    }
  }

  // Idle padrão: pulso sutil de escala vertical, como respirar.
  void _breathe(SpriteComponent visual, double flip) {
    final pulse = 1.0 + sin(_time * 2 * pi / _breathPeriod) * _breathAmplitude;
    visual.scale = Vector2(flip, pulse);
  }
}
