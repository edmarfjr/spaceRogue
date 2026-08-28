import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/enemies/enemy.dart';
import 'package:creatures_rogue/game/components/player/player.dart';

/// Linha + arco de progresso do laço de captura (PIVOT_TREINADOR.md §4.1) —
/// componente de mundo, não de Hud: segue o alvo (que se move, puxado pro
/// centro da sala enquanto enraizado — ver `Enemy.enraizarParaCaptura`) e
/// desenha a linha até o treinador (que também se move, é ele que anda a
/// volta). O arco fecha em 2π quando a captura completa.
class CaptureLassoVisual extends PositionComponent {
  final Player trainer;
  final Enemy alvo;
  final double raioAlvo;

  /// 0..1 — fração da volta completa (ver `Player._capturaAnguloAcumulado`).
  final double Function() fracao;

  final Paint _linha = Paint()
    ..color = Palette.branco
    ..strokeWidth = 1..filterQuality = FilterQuality.none;
  final Paint _contorno = Paint()
    ..color = Palette.preto
    ..strokeWidth = 3..filterQuality = FilterQuality.none;
  final Paint _arcoContorno = Paint()
    ..color = Palette.preto
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4..filterQuality = FilterQuality.none;
  final Paint _arcoFundo = Paint()
    ..color = Palette.cinzaEsc
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2..filterQuality = FilterQuality.none;
  final Paint _arcoProgresso = Paint()
    ..color = Palette.amarelo
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2..filterQuality = FilterQuality.none;

  CaptureLassoVisual({
    required this.trainer,
    required this.alvo,
    required this.raioAlvo,
    required this.fracao,
  }) : super(priority: 10);

  @override
  void update(double dt) {
    super.update(dt);
    position = alvo.absolutePosition;
  }

  @override
  void render(Canvas canvas) {
    final ateTreinador = trainer.absolutePosition - alvo.absolutePosition;
    canvas.drawLine(Offset.zero, Offset(ateTreinador.x, ateTreinador.y), _contorno);
    canvas.drawLine(Offset.zero, Offset(ateTreinador.x, ateTreinador.y), _linha);

    final rect = Rect.fromCircle(center: Offset.zero, radius: raioAlvo);
    canvas.drawArc(rect, 0, 2 * math.pi, false, _arcoContorno);
    canvas.drawArc(rect, 0, 2 * math.pi, false, _arcoFundo);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fracao().clamp(0.0, 1.0), false, _arcoProgresso);
  }
}
