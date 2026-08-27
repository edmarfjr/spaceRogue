import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'obstacle.dart';

class Door extends Obstacle {
  bool _isOpen;
  final double angleVal;
  final bool flipX;
  
  late Sprite _closedSprite;
  late Sprite _openSprite;

  final Color cor1;
  final Color cor2;
  final Color cor3;

  Door({
    required super.position,
    required this.angleVal,
    this.cor1 = Palette.marromEsc,
    this.cor2 = Palette.onyx,
    this.cor3 = Palette.verde,
    bool isOpen = false,
    this.flipX = false,
  })  : _isOpen = isOpen,
        
        super(
          spritePath: 'tileset/door.png',
          cor1: cor1,
          cor2: cor2,  
          cor3: cor3,  
          size: Vector2(16, 16),
          collisionType: isOpen ? CollisionType.inactive : CollisionType.passive,
        ) {
    anchor = Anchor.center;
    angle = angleVal;
    if (flipX) {
      scale = Vector2(1, -1);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    final ui.Image swappedImageClose = await PaletteSwapper.createSwappedImage(
      imagePath: 'tileset/arvore2.png',//'tileset/door1.png',
      lightGrayReplacement: cor1,
      darkGrayReplacement: cor2,
      whiteReplacement: cor3,
    );

    final ui.Image swappedImage = await PaletteSwapper.createSwappedImage(
      imagePath: 'tileset/floor.png',//'tileset/doorOpen1.png',
      lightGrayReplacement: Palette.branco,// cor1,
      darkGrayReplacement: Palette.branco,//cor2,
      whiteReplacement: Palette.branco,//cor3,
    );
    
    _closedSprite = Sprite(swappedImageClose);
    _openSprite = Sprite(swappedImage);

  }

  void open() {
    _isOpen = true;
    hitbox.collisionType = CollisionType.inactive;
  }

  void close() {
    _isOpen = false;
    hitbox.collisionType = CollisionType.passive;
  }

  @override
  void onMount() {
    super.onMount();
    position += size / 2;
  }

  @override
  void render(Canvas canvas) {
    final sprite = _isOpen ? _openSprite : _closedSprite;
    sprite.render(canvas, size: size, overridePaint: paint);
  }
}