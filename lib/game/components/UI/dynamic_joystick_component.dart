import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:creatures_rogue/game/components/UI/consumable_slot_button.dart';

/// Joystick "flutuante": ao contrário do `JoystickComponent` fixo do Flame,
/// não tem posição própria na tela. Ele cobre uma área (normalmente a metade
/// esquerda da tela) só pra capturar o toque; no instante em que o dedo
/// encosta, o visual (fundo + manípulo) nasce ali mesmo, e some quando o dedo
/// sai.
///
/// A matemática de `delta`/`intensity`/`relativeDelta` é a mesma do
/// `JoystickComponent` original do Flame — só o "centro" deixou de ser fixo
/// no `onMount` (campo privado da lib do Flame, inacessível por herança) pra
/// ser recalculado a cada toque em `onDragStart`.
class DynamicJoystickComponent extends PositionComponent with DragCallbacks {
  final PositionComponent knob;
  final PositionComponent background;
  final double knobRadius;

  final Vector2 delta = Vector2.zero();
  final Vector2 _unscaledDelta = Vector2.zero();
  Vector2 _baseKnobPosition = Vector2.zero();
  bool _active = false;

  double intensity = 0.0;

  /// Percentual (0..1 por eixo) e direção que o manípulo está puxado a
  /// partir do centro onde o dedo pousou. Zero quando não há toque ativo.
  Vector2 get relativeDelta => _active ? delta / knobRadius : Vector2.zero();

  DynamicJoystickComponent({
    required this.knob,
    required this.background,
    required Vector2 spawnAreaSize,
    double? knobRadius,
  }) : knobRadius = knobRadius ?? background.size.x / 2,
       super(size: spawnAreaSize, position: Vector2.zero()) {
    knob.anchor = Anchor.center;
    background.anchor = Anchor.center;
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    // A área de captura acompanha o tamanho real da tela — sem isso, girar o
    // aparelho ou redimensionar a janela deixaria a metade esquerda torta.
    //
    // A faixa do topo fica de fora: é onde vivem os slots do inventário, e um
    // toque neles não pode virar movimento (ver ConsumableSlotButton).
    size = Vector2(canvasSize.x / 2, canvasSize.y - ConsumableSlotButton.alturaFaixa);
    position = Vector2(0, ConsumableSlotButton.alturaFaixa);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;

    final knobRadius2 = knobRadius * knobRadius;
    delta.setFrom(_unscaledDelta);
    if (delta.length2 > knobRadius2) {
      delta.scaleTo(knobRadius);
    }
    knob.position
      ..setFrom(_baseKnobPosition)
      ..add(delta);
    intensity = delta.length2 / knobRadius2;
  }

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _active = true;
    _unscaledDelta.setZero();
    delta.setZero();

    _baseKnobPosition = event.localPosition.clone();
    background.position = _baseKnobPosition.clone();
    knob.position = _baseKnobPosition.clone();

    if (background.parent == null) add(background);
    if (knob.parent == null) add(knob);
    return false;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_active) return false;
    _unscaledDelta.add(event.localDelta);
    return false;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _hide();
    return false;
  }

  @override
  bool onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _hide();
    return false;
  }

  void _hide() {
    _active = false;
    _unscaledDelta.setZero();
    delta.setZero();
    intensity = 0.0;
    background.removeFromParent();
    knob.removeFromParent();
  }
}
