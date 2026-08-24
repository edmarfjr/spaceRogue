import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/UI/ability_icons.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';

/// Indicador de cooldown de uma habilidade na HUD: o ícone da habilidade com um
/// quadrado cinza por cima que esvazia de cima pra baixo.
///
/// O cinza cobre a parte de BAIXO com altura proporcional ao cooldown restante,
/// então o ícone é revelado do topo pra baixo e o cinza afunda até sumir quando
/// a habilidade fica pronta.
///
/// Isso substitui a fatia radial que o [AbilityButton] desenhava: o cooldown
/// agora vive na HUD e vale nos dois esquemas de controle, inclusive no de
/// gestos, que não tem botão nenhum pra desenhar em cima.
class AbilityCooldownIndicator extends PositionComponent {
  /// Papel da habilidade, que decide o ícone. Lido a cada frame porque a
  /// criatura — e portanto o par de habilidades — muda a cada run.
  final AbilityTipo Function() tipo;

  /// 0 = pronto, 1 = acabou de usar. Ver `Player.ability1CooldownFraction`.
  final double Function() cooldownFraction;

  /// `FilterQuality.none` mantém o pixel art nítido quando a câmera de
  /// resolução fixa escala a HUD inteira.
  final Paint _spritePaint = Paint()..filterQuality = FilterQuality.none;

  final Paint _cooldownPaint = Paint()..color = Palette.cinzaEsc.withAlpha(220);

  AbilityCooldownIndicator({
    required this.tipo,
    required this.cooldownFraction,
    required double lado,
    super.position,
  }) : super(size: Vector2.all(lado));

  @override
  void render(Canvas canvas) {
    AbilityIcons.of(tipo()).render(canvas, size: size, overridePaint: _spritePaint);

    final fraction = cooldownFraction().clamp(0.0, 1.0);
    if (fraction > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, size.y * (1 - fraction), size.x, size.y * fraction),
        _cooldownPaint,
      );
    }
  }
}
