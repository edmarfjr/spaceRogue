import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/UI/pointer_tracker.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';

/// Botão de captura (PIVOT_TREINADOR.md §2.1.1/§4.1) — segurar inicia o laço,
/// soltar cancela. Botão próprio, fora da troca de esquema de controle
/// (`_abilityControls`): compartilhar toque/arraste com override de
/// habilidade significaria distinguir toque curto de longo em pleno combate,
/// exatamente o tipo de input que falha na hora errada (decisão travada em
/// §2.1.1). Por isso existe nos dois esquemas igual, montado uma vez só —
/// mesmo tratamento que `ConsumableSlotButton`.
///
/// Sem ícone de sprite: nenhum asset de laço existe no projeto ainda. O
/// glifo é só um anel desenhado no `render`, primeiro corte.
class CaptureButton extends PositionComponent
    with HasGameReference, ComponentViewportMargin, TapCallbacks {
  final PointerTracker pointerTracker;
  final void Function(bool pressed) onPressedChanged;

  bool _tapDown = false;
  bool _pressed = false;

  final Paint _baseColor = Paint()..color = Palette.roxoEsc.withAlpha(255);
  final Paint _pressedColor = Paint()..color = Palette.roxoEsc.withAlpha(140);
  final Paint _glifo = Paint()
    ..color = Palette.branco
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  CaptureButton({
    required double radius,
    required this.pointerTracker,
    required this.onPressedChanged,
    EdgeInsets? margin,
  }) : super(size: Vector2.all(radius * 2)) {
    this.margin = margin;
  }

  /// Área de toque circular, igual ao círculo desenhado — mesmo motivo do
  /// `AbilityButton`.
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

    canvas.drawCircle(center, radius, _pressed ? _pressedColor : _baseColor);
    canvas.drawCircle(center, radius * 0.45, _glifo);
  }
}
