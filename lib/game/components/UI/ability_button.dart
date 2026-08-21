import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/UI/pointer_tracker.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';

/// Botão de habilidade do HUD: círculo de cor base, a letra no meio e uma fatia
/// escura por cima indicando quanto falta do cooldown (some conforme fica
/// pronto).
///
/// Não é um `HudButtonComponent`. Aquele reage só a `TapCallbacks`, ou seja: um
/// dedo que já estava na tela e desliza para dentro do botão nunca o ativava —
/// eventos de tap só nascem no instante em que o dedo pousa. Aqui o estado
/// "pressionado" é derivado de duas fontes, e a mudança é reportada por
/// [onPressedChanged]:
///
/// 1. Tap dentro do botão — resposta imediata, sem depender de movimento.
/// 2. Qualquer ponteiro de arraste do [PointerTracker] dentro do círculo — é
///    isso que faz o deslizar-para-dentro funcionar, e também o deslizar de um
///    botão para o outro (o primeiro solta, o segundo pressiona).
///
/// As duas se completam: quando o Flutter promove o toque de tap para arraste
/// (depois de ~18px de movimento) o tap é cancelado, mas nesse momento o
/// ponteiro já está sendo rastreado — não sobra buraco entre as duas fontes.
class AbilityButton extends PositionComponent
    with HasGameReference, ComponentViewportMargin, TapCallbacks {
  final Color baseColor;
  final Color pressedColor;
  final Color cooldownColor;
  final double Function() cooldownFraction;
  final String text;
  final PointerTracker pointerTracker;
  final void Function(bool pressed) onPressedChanged;

  bool _tapDown = false;
  bool _pressed = false;

  AbilityButton({
    required double radius,
    required this.baseColor,
    required this.pressedColor,
    required this.cooldownColor,
    required this.cooldownFraction,
    required this.text,
    required this.pointerTracker,
    required this.onPressedChanged,
    EdgeInsets? margin,
    // Sem anchor explícito: fica em Anchor.topLeft, e é esse canto que o
    // ComponentViewportMargin usa pra calcular a posição a partir da margem.
  }) : super(size: Vector2.all(radius * 2)) {
    this.margin = margin;
  }

  /// Área de toque circular, igual ao círculo desenhado. O `containsLocalPoint`
  /// padrão é o retângulo do `size`, o que daria cantos clicáveis fora do
  /// visual — atrapalha justamente no deslize entre os dois botões, onde os
  /// cantos de um invadem a vizinhança do outro.
  @override
  bool containsLocalPoint(Vector2 point) {
    final radius = size.x / 2;
    final dx = point.x - radius;
    final dy = point.y - radius;
    return dx * dx + dy * dy <= radius * radius;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _refreshPressed();
  }

  void _refreshPressed() {
    final down = _tapDown || pointerTracker.anyInside(this);
    if (down == _pressed) return;
    _pressed = down;
    onPressedChanged(down);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _tapDown = true;
    _refreshPressed();
  }

  @override
  void onTapUp(TapUpEvent event) {
    _tapDown = false;
    _refreshPressed();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _tapDown = false;
    _refreshPressed();
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = _pressed ? pressedColor : baseColor,
    );

    final paint = TextPaint(
      style: TextStyle(
        color: Palette.preto,
        fontSize: radius,
        fontFamily: 'pixelFont',
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Palette.preto, offset: const Offset(1, 1)),
        ],
      ),
    );
    paint.render(canvas, text, center.toVector2(), anchor: Anchor.center);

    final fraction = cooldownFraction().clamp(0.0, 1.0);
    if (fraction > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, -pi / 2, fraction * 2 * pi, true, Paint()..color = cooldownColor);
    }
  }
}
