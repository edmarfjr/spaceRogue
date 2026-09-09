import 'dart:ui';

import 'package:flame/components.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/map/room_component.dart';
import '../player/player.dart';

/// Transição de andar: um círculo preto fecha sobre o jogador, o novo andar
/// é montado por baixo com a tela já coberta, e o círculo reabre.
///
/// Mesma técnica de recorte do [BlindOverlay] (buraco redondo cortado de um
/// retângulo preto via `Path.combine`), mas aqui o raio vai até 0 — cobre a
/// tela inteira — em vez de parar num mínimo visível.
class LevelTransitionOverlay extends PositionComponent {
  final Player player;
  final CameraComponent camera;

  /// Chamado uma vez, no instante em que o círculo termina de fechar (tela
  /// 100% preta) — é aí que o chamador troca o andar por baixo, escondido.
  final void Function() aoFechar;

  static const double _duracaoFechar = 1.00;
  static const double _duracaoAbrir = 1.00;

  double _tempo = 0;
  bool _fechou = false;

  LevelTransitionOverlay({
    required this.player,
    required this.camera,
    required this.aoFechar,
  }) : super(
         size: Vector2(RoomComponent.roomWidth, RoomComponent.roomHeight),
         // Acima de tudo (HUD, minimapa, barra de boss) — a troca de andar
         // por baixo não pode vazar por trás desses elementos.
         priority: 1000,
       );

  @override
  void update(double dt) {
    super.update(dt);
    _tempo += dt;
    if (!_fechou && _tempo >= _duracaoFechar) {
      _fechou = true;
      aoFechar();
    }
    if (_tempo >= _duracaoFechar + _duracaoAbrir) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // viewfinder.position é o ponto do mundo que cai no centro da viewport.
    final desloc = player.absolutePosition - camera.viewfinder.position;
    final centro = Offset(size.x / 2 + desloc.x, size.y / 2 + desloc.y);

    // A câmera trava por sala, não segue o jogador — ele pode estar longe do
    // centro da viewport, então um raio fixo "abria" o buraco pra fora da
    // tela antes de cobrir tudo (preto cedo demais). Em vez disso, cobre
    // exatamente a distância até o canto mais longe do retângulo visível.
    final raioAberto = [
      (centro - Offset.zero).distance,
      (centro - Offset(size.x, 0)).distance,
      (centro - Offset(0, size.y)).distance,
      (centro - Offset(size.x, size.y)).distance,
    ].reduce((a, b) => a > b ? a : b);

    final double raio;
    if (_tempo < _duracaoFechar) {
      final progresso = (_tempo / _duracaoFechar).clamp(0.0, 1.0);
      raio = raioAberto * (1 - progresso);
    } else {
      final progresso = ((_tempo - _duracaoFechar) / _duracaoAbrir).clamp(
        0.0,
        1.0,
      );
      raio = raioAberto * progresso;
    }

    final escuro = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.x, size.y)),
      Path()..addOval(Rect.fromCircle(center: centro, radius: raio)),
    );

    canvas.drawPath(escuro, Paint()..color = Palette.preto);
  }
}
