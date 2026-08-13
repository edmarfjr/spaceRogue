import 'dart:ui';

import 'package:flame/components.dart';
import 'package:spacerogue/game/components/utils/palette.dart';

// Não herda mais de BaseObstacle! Herda direto de SpriteComponent.
class WallTile extends SpriteComponent with HasGameRef {
  final String spritePath;
  final double angleVal;
  final Color? colorModulate;

  WallTile({
    required Vector2 position,
    required this.spritePath,
    this.angleVal = 0,
    this.colorModulate = Palette.marromEsc,
  }) : super(
         position: position,
         size: Vector2(16, 16), // Tamanho do bloco
       ) {
    anchor = Anchor.center; // Permite rodar em torno do próprio eixo
    angle = angleVal;
  }

  @override
  Future<void> onLoad() async {
    // Carrega o sprite visualmente, sem criar nenhuma Hitbox!
    sprite = await gameRef.loadSprite(spritePath);
    if (colorModulate != null) {
      paint.colorFilter = ColorFilter.mode(colorModulate!, BlendMode.modulate);
    }
  }

  @override
  void onMount() {
    super.onMount();
    position += size / 2; // Centraliza a âncora no grid
  }
}