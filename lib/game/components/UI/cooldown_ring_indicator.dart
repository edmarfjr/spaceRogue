import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/UI/ability_icons.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';

/// Anelzinho de cooldown desenhado no MUNDO, em cima do sprite da criatura
/// ativa — mesma leitura do [AbilityCooldownIndicator] da HUD (cinza cobre o
/// que falta, some quando pronto), mas com o ícone da habilidade em vez de
/// ícone de habilidade fixo, e junto do personagem em vez de fixo na tela.
class CooldownRingIndicator extends PositionComponent {
  final AbilityTipo Function() tipo;
  final double Function() cooldownFraction;

  final Paint _spritePaint = Paint()..filterQuality = FilterQuality.none;
  final Paint _restante = Paint()..color = Palette.cinzaEsc.withAlpha(230);

  CooldownRingIndicator({
    required this.tipo,
    required this.cooldownFraction,
    required double raio,
    super.position,
  }) : super(size: Vector2.all(raio * 2), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;

    final fraction = cooldownFraction().clamp(0.0, 1.0);
    if (fraction <= 0){
      AbilityIcons.ofP(tipo()).render(canvas, size: size, overridePaint: _spritePaint);
    }else{
      canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * fraction,
      true,
      _restante,
    );
    }

    
  }
}
