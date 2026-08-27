import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';

/// Botão de recolher/liberar o grupo (PIVOT_TREINADOR.md, pedido do
/// usuário) — TOQUE, não segurar: é troca de estado (recolhido/fora), não
/// uma ação contínua como esquiva/captura. Mesmo padrão de
/// `ConsumableSlotButton` (só `TapCallbacks`, dispara no `onTapUp`).
///
/// Sem ícone de sprite — glifo é uma seta desenhada no `render`, primeiro
/// corte, nenhum asset novo.
class RecallButton extends PositionComponent
    with HasGameReference, ComponentViewportMargin, TapCallbacks {
  final VoidCallback onToggle;

  /// Se o grupo tá recolhido agora — só muda a cor/glifo, não o
  /// comportamento do toque (sempre `onToggle`, quem decide direção é
  /// `CreaturesRogueGame.alternarRecuoGrupo`).
  final bool Function() recolhido;

  final Paint _baseColor = Paint()..color = Palette.royal.withAlpha(255);
  final Paint _glifo = Paint()
    ..color = Palette.branco
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  RecallButton({
    required double radius,
    required this.onToggle,
    required this.recolhido,
    EdgeInsets? margin,
  }) : super(size: Vector2.all(radius * 2)) {
    this.margin = margin;
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    final radius = size.x / 2;
    final dx = point.x - radius;
    final dy = point.y - radius;
    return dx * dx + dy * dy <= radius * radius;
  }

  @override
  void onTapUp(TapUpEvent event) => onToggle();

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;

    canvas.drawCircle(center, radius, _baseColor);

    // Seta pra dentro (recolher) ou pra fora (liberar) — dois traços em V,
    // apontando pro centro ou pra fora dele.
    final ponta = radius * 0.5;
    final cauda = radius * 0.85;
    if (recolhido()) {
      // Setas apontando pra FORA do centro — "liberar".
      canvas.drawLine(center, center - Offset(cauda, 0), _glifo);
      canvas.drawLine(center - Offset(cauda, 0), center - Offset(ponta, ponta * 0.6), _glifo);
      canvas.drawLine(center - Offset(cauda, 0), center - Offset(ponta, -ponta * 0.6), _glifo);
    } else {
      // Setas apontando PRA o centro — "recolher".
      canvas.drawLine(center + Offset(cauda, 0), center, _glifo);
      canvas.drawLine(center + Offset(ponta, ponta * 0.6), center, _glifo);
      canvas.drawLine(center + Offset(ponta, -ponta * 0.6), center, _glifo);
    }
  }
}
