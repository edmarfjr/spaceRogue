import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:spacerogue/game/components/utils/palette.dart';
import 'obstacle.dart';

class Door extends Obstacle {
  bool _isOpen;
  final double angleVal;
  final bool flipX;
  
  late Sprite _closedSprite;
  late Sprite _openSprite;

  Door({
    required Vector2 position,
    required this.angleVal,
    Color? colorModulate = Palette.marromEsc,
    bool isOpen = false,
    this.flipX = false,
  })  : _isOpen = isOpen,
        
        super(
          position: position,
          spritePath: 'tileset/door.png',
          colorModulate: colorModulate,
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
    // 1. Chama o onLoad da superclasse (Obstacle), que já vai carregar 
    // o obstacleSprite padrão e aplicar o colorModulate na 'paint' automaticamente!
    await super.onLoad();

    // 2. Carrega especificamente os dois sprites para alternar entre aberto/fechado
    _closedSprite = await gameRef.loadSprite('tileset/door.png');
    _openSprite = await gameRef.loadSprite('tileset/doorOpen.png');

    priority = 100;
  }

  void open() {
    _isOpen = true;
    // Desativa colisão
    firstChild<RectangleHitbox>()?.collisionType = CollisionType.inactive;
  }

  void close() {
    _isOpen = false;
    firstChild<RectangleHitbox>()?.collisionType = CollisionType.passive;
  }

  @override
  void onMount() {
    super.onMount();
    position += size / 2; // Ajuste fino da âncora
  }

  @override
  void render(Canvas canvas) {
    // Escolhe o sprite correto e desenha
    final sprite = _isOpen ? _openSprite : _closedSprite;
    sprite.render(canvas, size: size, overridePaint: paint);
  }
}