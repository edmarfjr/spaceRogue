import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';

/// Pequena "explosão" quando uma criatura entra em campo — troca voluntária
/// pro banco (`_trocarParaSlot`), troca automática depois de um desmaio
/// (`pocketarSlotAtivo`), ou recrutamento na sala da escada
/// (`recrutarCriaturaSelvagem`, ver PIVOT_CONTROLE_DIRETO.md) — um círculo
/// branco se abre rápido e desaparece. Puramente Canvas, mesmo espírito de
/// `CompanionRecallEffect`.
class CompanionReviveEffect extends PositionComponent {
  static const double _duracao = 0.25;
  static const double _raioMax = 14.0;

  double _tempo = 0.0;

  CompanionReviveEffect({required Vector2 position})
      : super(position: position.clone(), priority: 200);

  @override
  void update(double dt) {
    super.update(dt);
    _tempo += dt;
    if (_tempo >= _duracao) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_tempo / _duracao).clamp(0.0, 1.0);
    final raio = _raioMax * t;
    if (raio <= 0) return;

    //final alpha = 255;//((1 - t) * 255).round().clamp(0, 255);
    final Paint borda = Paint()..color = Palette.preto..style = PaintingStyle.stroke..strokeWidth = 1..filterQuality = FilterQuality.none;
    final Paint borda2 = Paint()..color = Palette.branco..style = PaintingStyle.stroke..strokeWidth = 1..filterQuality = FilterQuality.none;

    canvas.drawCircle(Offset.zero, raio, Paint()..color = Palette.vermelho..style = PaintingStyle.stroke..strokeWidth = 1..filterQuality = FilterQuality.none);
    canvas.drawCircle(Offset.zero, raio+1,borda);
    canvas.drawCircle(Offset.zero, raio-1,borda2);
    
  }
}
