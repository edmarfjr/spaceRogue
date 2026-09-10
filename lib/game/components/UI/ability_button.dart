import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:creatures_rogue/game/components/UI/ability_button_sprites.dart';
import 'package:creatures_rogue/game/components/UI/pointer_tracker.dart';
import 'package:creatures_rogue/game/components/creatures/ability.dart';

/// Botão de habilidade: sprite de dois quadros (`ui/btn<Tipo>.png`, ver
/// `AbilityButtonSprites`) — neutro e pressionado, sem círculo/ícone
/// desenhados por cima.
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
/// 2. Qualquer ponteiro de arraste do [PointerTracker] dentro do botão — é
///    isso que faz o deslizar-para-dentro funcionar, e também o deslizar de um
///    botão para o outro (o primeiro solta, o segundo pressiona).
///
/// As duas se completam: quando o Flutter promove o toque de tap para arraste
/// (depois de ~18px de movimento) o tap é cancelado, mas nesse momento o
/// ponteiro já está sendo rastreado — não sobra buraco entre as duas fontes.
class AbilityButton extends PositionComponent
    with HasGameReference, ComponentViewportMargin, TapCallbacks {
  /// Papel da habilidade, que decide o sprite — o mesmo que o indicador de
  /// cooldown da HUD usa pro ícone. Lido a cada frame: o botão é montado no
  /// onLoad do jogo, antes de existir jogador, e a criatura muda a cada run.
  final AbilityTipo Function() tipo;

  final PointerTracker pointerTracker;
  final void Function(bool pressed) onPressedChanged;

  bool _tapDown = false;
  bool _pressed = false;

  /// `FilterQuality.none` mantém o pixel art nítido: o sprite é 24x24 e o
  /// botão tem 100px de diâmetro no mobile.
  final Paint _spritePaint = Paint()..filterQuality = FilterQuality.none;

  AbilityButton({
    required double radius,
    required this.tipo,
    required this.pointerTracker,
    required this.onPressedChanged,
    EdgeInsets? margin,
    // Sem anchor explícito: fica em Anchor.topLeft, e é esse canto que o
    // ComponentViewportMargin usa pra calcular a posição a partir da margem.
  }) : super(size: Vector2.all(radius * 2)) {
    this.margin = margin;
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
    final sprite = _pressed
        ? AbilityButtonSprites.pressionado(tipo())
        : AbilityButtonSprites.neutro(tipo());
    sprite.render(canvas, size: size, overridePaint: _spritePaint);
  }
}
