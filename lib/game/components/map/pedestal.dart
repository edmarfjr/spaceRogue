import 'dart:math';

import 'package:creatures_rogue/game/components/items/consumable_item.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/items/item_efeito.dart';
import 'package:creatures_rogue/game/components/items/power_up_item.dart';
import 'package:creatures_rogue/game/components/map/obstacle.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';

class PedestalComponent extends Obstacle {
  late final Sprite pedestalSprite;
  
  bool hasItem = true;

  PedestalComponent({required super.position, super.cor1 = Palette.indigo,super.cor2 = Palette.cinzaEsc}) 
      : super(
          spritePath: 'tileset/pedestal.png',
          size: Vector2(16, 16),
          collisionType: CollisionType.passive,
        );

  /// O sorteio mora aqui, e não no construtor, porque a família ITEM_EFEITO
  /// precisa consultar a pool da run — e `game` só existe depois da montagem.
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final rng = Random();
    final jogo = game;

    // Uma chance em três pra cada família. ITEM_EFEITO é o único que consulta
    // a pool: `sortearItemEfeito` já retira o item, então a mesma run nunca
    // oferece o mesmo duas vezes. Pool vazia devolve `null` e o sorteio recai
    // nas outras duas famílias — pedestal nenhum fica vazio por isso.
    final familia = rng.nextInt(3);
    final item = familia == 0 && jogo is CreaturesRogueGame
        ? jogo.sortearItemEfeito()
        : null;

    if (item != null) {
      add(ItemEfeitoPickup(position: Vector2(8, -4), item: item));
    } else if (familia == 1 || (familia == 0 && rng.nextBool())) {
      add(ConsumablePickup(
        position: Vector2(8, -4),
        tipo: ConsumableType.values[rng.nextInt(ConsumableType.values.length)],
      ));
    } else {
      add(PowerUpItem(
        position: Vector2(8, -4),
        tipo: PowerUpType.values[rng.nextInt(PowerUpType.values.length)],
      ));
    }
  }
/*
  @override
  Future onLoad() async {
    // Crie um pedestal.png na sua pasta assets/images/
    
    // Colisão física para o jogador não conseguir atravessar o pedestal por cima
    add(RectangleHitbox(
      size: Vector2(12, 12), 
      anchor: Anchor.center, 
      position: size / 2, 
      collisionType: CollisionType.passive,
    ));
  }

  @override
  void render(Canvas canvas) {
    pedestalSprite.render(canvas, size: size, overridePaint: paint);
  }
  */
}