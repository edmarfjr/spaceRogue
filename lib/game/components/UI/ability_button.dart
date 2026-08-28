import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:creatures_rogue/game/components/UI/ability_icons.dart';
import 'package:creatures_rogue/game/components/UI/pointer_tracker.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';

/// Botão de habilidade: círculo de cor base com o ícone da habilidade no meio.
///
/// Não desenha cooldown: isso agora é do `AbilityCooldownIndicator`, na HUD,
/// que vale também no esquema de gestos — onde não existe botão em que desenhar.
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

  /// Papel da habilidade, que decide o ícone — o mesmo que o indicador de
  /// cooldown da HUD desenha. Lido a cada frame: o botão é montado no onLoad do
  /// jogo, antes de existir jogador, e a criatura muda a cada run.
  final AbilityTipo Function() tipo;

  final PointerTracker pointerTracker;
  final void Function(bool pressed) onPressedChanged;

  bool _tapDown = false;
  bool _pressed = false;

  /// `FilterQuality.none` mantém o pixel art nítido: o sprite é 16x16 e o botão
  /// tem 100px de diâmetro no mobile.
  final Paint _spritePaint = Paint()..filterQuality = FilterQuality.none..colorFilter..color=Palette.cinza..blendMode=BlendMode.multiply;

  AbilityButton({
    required double radius,
    required this.baseColor,
    required this.pressedColor,
    required this.tipo,
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
    if (down) HapticFeedback.lightImpact();
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
      radius*1.1,
      Paint()..color = Palette.preto,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = _pressed ? pressedColor : baseColor,
    );

    // Ícone com 60% do diâmetro, centralizado — folga suficiente pra borda do
    // círculo continuar visível como alvo de toque.
    final iconSize = Vector2.all(size.x*0.6);
    AbilityIcons.of(tipo()).render(
      canvas,
      position: (size - iconSize) / 2,
      size: iconSize,
      overridePaint: _spritePaint,
    );
  }
}
