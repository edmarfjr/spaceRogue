import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// Rastreia a posição de TODOS os ponteiros de arraste ativos na tela, não
/// importa qual componente capturou o toque.
///
/// Por que isso é necessário: o `MultiDragDispatcher` do Flame entrega
/// `onDragUpdate` apenas ao componente que capturou o `onDragStart`. Um botão,
/// portanto, nunca fica sabendo que um dedo que começou o arraste em outro
/// lugar entrou na sua área. Mas o mesmo dispatcher publica todos os eventos
/// em streams broadcast — e é delas que este componente vive.
///
/// Limitação herdada do Flutter: o `ImmediateMultiDragGestureRecognizer` só
/// promove o toque a arraste depois de o dedo andar mais que `kTouchSlop`
/// (~18px). Um dedo que pousa e desliza MENOS que isso não gera evento de
/// arraste nenhum; quem cobre esse caso é o tap do próprio botão.
class PointerTracker extends Component with DragCallbacks {
  final Map<int, Vector2> _positions = {};
  final List<StreamSubscription<void>> _subscriptions = [];

  /// True se algum ponteiro ativo está dentro de [component].
  bool anyInside(PositionComponent component) {
    if (_positions.isEmpty) return false;
    return _positions.values.any(component.containsPoint);
  }

  @override
  void onMount() {
    // O `DragCallbacks` aqui não é pra receber evento: um `Component` puro tem
    // `containsLocalPoint == false`, então nada é entregue a ele. Ele existe pra
    // garantir que o `MultiDragDispatcher` já esteja registrado no jogo quando a
    // busca abaixo acontecer, independente da ordem em que os componentes com
    // arraste (joystick, este) forem montados.
    super.onMount();

    final dispatcher = findRootGame()!.findByKey(const MultiDragDispatcherKey())!
        as MultiDragDispatcher;

    _subscriptions.addAll([
      dispatcher.onStart.listen((e) => _positions[e.pointerId] = e.canvasPosition),
      dispatcher.onUpdate.listen((e) => _positions[e.pointerId] = e.canvasEndPosition),
      dispatcher.onEnd.listen((e) => _positions.remove(e.pointerId)),
      dispatcher.onCancel.listen((e) => _positions.remove(e.pointerId)),
    ]);
  }

  @override
  void onRemove() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _positions.clear();
    super.onRemove();
  }
}
