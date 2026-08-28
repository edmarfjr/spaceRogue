import 'dart:ui' as ui;
import 'package:creatures_rogue/game/audio/game_audio.dart';
import 'package:creatures_rogue/game/audio/sfx.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';

import '../player/player.dart';

// A classe é abstrata, não pode ser instanciada diretamente.
abstract class Collectible extends PositionComponent with CollisionCallbacks, HasGameRef {
  final String spritePath; // Cada filho dirá qual imagem carregar
  final Color cor1;
  final Color cor2;

  late final Sprite _sprite;
  final Paint _paint = Paint()..filterQuality = FilterQuality.none;

  Collectible({
    required Vector2 position,
    required this.spritePath,
    this.cor1 = Palette.cinza,
    this.cor2 = Palette.cinzaEsc,
  }) : super(position: position, size: Vector2(16, 16), anchor: Anchor.center);

  @override
  Future onLoad() async {

    final ui.Image img = await PaletteSwapper.createSwappedImage(
      imagePath: spritePath,
      lightGrayReplacement: cor1,
      darkGrayReplacement: cor2,
    );
    

    _sprite = Sprite(img);
    
    add(RectangleHitbox(
      size: Vector2(16, 16),
      anchor: Anchor.center,
      position: size / 2,
      collisionType: CollisionType.passive,
    ));
  }

  @override
  void render(Canvas canvas) {
    _sprite.render(canvas, size: size, overridePaint: _paint);
  }

  @override
  void onCollisionStart(Set intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints.cast(), other);
    
    if (other is Player) {
      // Chama o método abstrato que os filhos vão implementar
      bool wasCollected = onCollect(other); 
      
      if (wasCollected) {
        GameAudio.instance.play(Sfx.pick);
        removeFromParent();
      }
    }
  }

  // NOVO: Método abstrato!
  // Retorna 'true' se o item foi consumido, ou 'false' se não (ex: vida já estava cheia)
  bool onCollect(Player player); 
}