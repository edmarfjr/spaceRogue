import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Visual de um botão de habilidade: um círculo de cor base com uma fatia
/// escura por cima indicando quanto falta do cooldown (some conforme fica
/// pronto). Usado como `button`/`buttonDown` de um `HudButtonComponent`.
class AbilityButtonVisual extends PositionComponent {
  final Color baseColor;
  final Color cooldownColor;
  final double Function() cooldownFraction;

  AbilityButtonVisual({
    required double radius,
    required this.baseColor,
    required this.cooldownColor,
    required this.cooldownFraction,
    // Sem anchor explícito: fica em Anchor.topLeft, igual ao CircleComponent
    // que esse componente substituiu. HudButtonComponent usa o tamanho e a
    // posição deste filho para calcular a área de toque — se o anchor não
    // bater, o círculo desenhado fica deslocado da área realmente clicável.
  }) : super(size: Vector2.all(radius * 2));

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;

    canvas.drawCircle(center, radius, Paint()..color = baseColor);

    final fraction = cooldownFraction().clamp(0.0, 1.0);
    if (fraction > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, -pi / 2, fraction * 2 * pi, true, Paint()..color = cooldownColor);
    }
  }
}
