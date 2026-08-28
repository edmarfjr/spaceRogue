import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/ui_theme.dart';

/// Moldura escura ao redor da área jogável, imitando o vão preto que cerca o
/// LCD no Game Boy de verdade — o resto da tela (fora da resolução fixa da
/// câmera) já é o cinza do "plástico" (ver [UiTheme.screenBackground]).
///
/// Fica na raiz do jogo (não dentro de `gameCamera.viewport`) porque precisa
/// da posição/tamanho do viewport em coordenadas de tela, não do mundo — lido
/// direto da câmera a cada frame, então acompanha rotação/resize sem precisar
/// de listener nenhum.
class GameboyBezel extends Component {
  GameboyBezel({required this.camera});

  final CameraComponent camera;

  static const double _thickness = 6;
  static const Radius _corner = Radius.circular(4);

  final Paint _paint = Paint()
    ..color = UiTheme.screenBezel
    ..style = PaintingStyle.stroke
    ..strokeWidth = _thickness;

  @override
  void render(Canvas canvas) {
    final position = camera.viewport.position;
    final size = camera.viewport.size;

    final rect = Rect.fromLTWH(
      position.x - _thickness / 2,
      position.y - _thickness / 2,
      size.x + _thickness,
      size.y + _thickness,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(rect, _corner), _paint);
  }
}
