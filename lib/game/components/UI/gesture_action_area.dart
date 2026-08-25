import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:creatures_rogue/game/components/UI/consumable_slot_button.dart';

/// Esquema de controle alternativo aos botões A/B: uma área invisível (na
/// prática, a metade direita da tela) onde o TIPO do gesto escolhe a
/// habilidade, em vez da posição do dedo.
///
/// - Toque parado (e mantido) dispara [onTapHoldChanged] — o antigo botão A.
/// - Arrastar o dedo dispara [onDragHoldChanged] — o antigo botão B.
///
/// A separação entre os dois sai de graça do próprio Flutter: o
/// `ImmediateMultiDragGestureRecognizer` só promove um toque a arraste depois
/// que o dedo anda mais que `kTouchSlop` (~18px). Até lá o gesto é um tap; a
/// partir dali o tap é cancelado e o arraste assume. Ou seja, "parado" e
/// "arrastando" já são estados mutuamente exclusivos decididos pela arena de
/// gestos — não precisa de limiar próprio.
///
/// Uma vez que o gesto virou arraste ele NÃO volta a ser toque parado: parar o
/// dedo no meio do caminho mantém a habilidade 2. O gesto só acaba quando o
/// dedo sai da tela.
///
/// O estado é por ponteiro, não global: dois dedos na metade direita são
/// independentes, e soltar um não cancela o gesto do outro.
class GestureActionArea extends PositionComponent
    with TapCallbacks, DragCallbacks {
  /// Chamado quando o conjunto de toques parados passa de vazio pra não-vazio
  /// e vice-versa.
  final void Function(bool active) onTapHoldChanged;

  /// Mesma ideia, para os arrastes.
  final void Function(bool active) onDragHoldChanged;

  final Set<int> _tapPointers = {};
  final Set<int> _dragPointers = {};

  bool _tapActive = false;
  bool _dragActive = false;

  GestureActionArea({
    required this.onTapHoldChanged,
    required this.onDragHoldChanged,
    super.priority,
  });

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    // Metade direita da tela. Acompanha o tamanho real pra não ficar torta ao
    // girar o aparelho ou redimensionar a janela — mesma razão do
    // DynamicJoystickComponent, que cobre a metade esquerda.
    //
    // Como no joystick, a faixa do topo fica de fora: sem isso um toque num
    // slot do inventário também dispararia a habilidade 1, ou seja, usar uma
    // poção gastaria a habilidade no mesmo toque.
    size = Vector2(canvasSize.x / 2, canvasSize.y - ConsumableSlotButton.alturaFaixa);
    position = Vector2(canvasSize.x / 2, ConsumableSlotButton.alturaFaixa);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _tapPointers.add(event.pointerId);
    _notify();
  }

  @override
  void onTapUp(TapUpEvent event) => _releaseTap(event.pointerId);

  @override
  void onTapCancel(TapCancelEvent event) => _releaseTap(event.pointerId);

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    // O tap deste mesmo dedo está sendo cancelado pela arena de gestos neste
    // instante, mas a ordem das duas notificações não é garantida — então é o
    // próprio onDragStart que tira o ponteiro do conjunto de toques. É o ÚNICO
    // lugar que muda o canal do gesto, e por isso os métodos de fim de gesto
    // abaixo mexem só no canal deles: se `onTapCancel` também limpasse o
    // arraste, um cancelamento que chegasse depois do onDragStart derrubaria a
    // habilidade 2 no mesmo frame em que ela começou.
    _tapPointers.remove(event.pointerId);
    _dragPointers.add(event.pointerId);
    _notify();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _releaseDrag(event.pointerId);
  }

  void _releaseTap(int pointerId) {
    if (_tapPointers.remove(pointerId)) _notify();
  }

  void _releaseDrag(int pointerId) {
    if (_dragPointers.remove(pointerId)) _notify();
  }

  void _notify() {
    final tap = _tapPointers.isNotEmpty;
    final drag = _dragPointers.isNotEmpty;
    if (tap != _tapActive) {
      _tapActive = tap;
      onTapHoldChanged(tap);
    }
    if (drag != _dragActive) {
      _dragActive = drag;
      onDragHoldChanged(drag);
    }
  }
}
