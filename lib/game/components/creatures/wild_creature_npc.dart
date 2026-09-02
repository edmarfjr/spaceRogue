import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/audio/game_audio.dart';
import 'package:creatures_rogue/game/audio/sfx.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/creatures/creature_data.dart';
import 'package:creatures_rogue/game/components/effects/companion_revive_effect.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/utils/palette_swapper.dart';
import 'package:creatures_rogue/game/components/utils/y_sort.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';

/// Criatura selvagem parada na sala da escada do quarto andar de cada
/// dungeon (ver PIVOT_CONTROLE_DIRETO.md §5) — sem IA de combate nenhuma, só
/// um sprite e um hitbox passivo. Encostar recruta na hora, sem confirmação
/// (pedido explícito de simplicidade): se o grupo tiver slot livre, entra no
/// banco com vida cheia; se a corrida rara acontecer (grupo se encheu entre
/// a sala nascer e o toque), não faz nada e a criatura continua ali.
class WildCreatureNpc extends PositionComponent
    with CollisionCallbacks, HasGameRef<CreaturesRogueGame> {
  final CreatureData creatureData;

  late final SpriteComponent _visual;

  /// `removeFromParent()` só tira o componente no FIM do frame — até lá,
  /// `Player.playerHitbox` e `Player.physicsHitbox` (dois hitboxes ativos
  /// distintos) podem cada um disparar `onCollisionStart` contra este hitbox
  /// passivo no mesmo instante. Sem essa trava, os dois eventos chamavam
  /// `recrutarCriaturaSelvagem` antes da remoção surtir efeito e preenchiam
  /// dois slots do grupo com a mesma criatura.
  bool _recrutado = false;

  WildCreatureNpc({required Vector2 position, required this.creatureData})
      : super(size: Vector2(16, 16), anchor: Anchor.center, position: position);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final ui.Image spriteImage = await PaletteSwapper.createSwappedImage(
      imagePath: creatureData.spritePath,
      lightGrayReplacement: creatureData.corClara,
      darkGrayReplacement: creatureData.corEscura,
    );

    final visualBasePosition = Vector2(size.x / 2, size.y);

    _visual = SpriteComponent(
      sprite: Sprite(spriteImage),
      size: size,
      anchor: Anchor.bottomCenter,
      position: visualBasePosition,
      paint: Paint()..filterQuality = FilterQuality.none,
      priority: 1,
    );
    add(_visual);

    final shadow = CircleComponent(
      radius: creatureData.hitboxSize.x / 2,
      anchor: Anchor.center,
      position: visualBasePosition,
      paint: Paint()..color = Palette.preto,
      priority: -1,
    )..scale = Vector2(1.2, 0.75);
    add(shadow);

    add(RectangleHitbox(
      size: creatureData.hitboxSize,
      anchor: Anchor.bottomCenter,
      position: visualBasePosition,
      collisionType: CollisionType.passive,
    ));

    priority = ySortPriority(position.y + size.y / 2);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (_recrutado || other is! Player) return;

    if (gameRef.recrutarCriaturaSelvagem(creatureData)) {
      _recrutado = true;
      GameAudio.instance.play(Sfx.liberar);
      parent?.add(CompanionReviveEffect(position: position.clone()));
      removeFromParent();
    }
  }
}
