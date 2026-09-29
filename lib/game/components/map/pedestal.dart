import 'dart:math';

import 'package:creatures_rogue/game/components/items/collectible.dart';
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

  /// Este pedestal ainda tem algo a oferecer?
  ///
  /// Vira false de duas formas: o jogador levou o item daqui, ou levou o do
  /// [irmao] e esta oferta foi encerrada junto (ver [encerrarOferta]).
  bool hasItem = true;

  /// Os OUTROS pedestais da mesma oferta (ver `RoomComponent._spawnTreasure`).
  /// Vazia num pedestal sozinho — é o caso da sala de desafio —, e aí nada
  /// nesta classe muda em relação a antes.
  ///
  /// Lista, e não uma referência só, por causa do `MapaDoTesouro`: com ele a
  /// sala põe três.
  final List<PedestalComponent> irmaos = [];

  /// Qual família de item este pedestal oferece: 0 = ITEM_EFEITO,
  /// 1 = CONSUMÍVEL, 2 = UPGRADE. `null` sorteia na hora, que é o
  /// comportamento do pedestal sozinho.
  final int? familia;

  /// A família do [irmao], quando há um. Serve só pro desempate do caso em
  /// que a pool de ITEM_EFEITO acaba: sem isto, um pedestal de ITEM_EFEITO
  /// sem pool cairia num sorteio livre e poderia acabar oferecendo o MESMO
  /// item do irmão — que é justamente o que uma escolha não pode ser.
  final int? familiaIrmao;

  /// Já vi um coletável nascer aqui?
  ///
  /// Sem isto, [update] veria "pedestal sem item" no primeiro quadro — o
  /// [onLoad] é assíncrono e o coletável só nasce um pouco depois — e
  /// encerraria a oferta do irmão sozinho, antes de o jogador encostar em
  /// nada. Mesma armadilha que a sala de desafio já tinha (ver
  /// `RoomComponent._itemDesafioApareceu`).
  bool _itemApareceu = false;

  PedestalComponent({
    required super.position,
    super.cor1 = Palette.indigo,
    super.cor2 = Palette.cinzaEsc,
    this.familia,
    this.familiaIrmao,
  }) : super(
         spritePath: 'tileset/pedestal.png',
         size: Vector2(16, 16),
         collisionType: CollisionType.passive,
       );

  /// O sorteio mora aqui, e não no construtor, porque a família ITEM_EFEITO
  /// precisa consultar a pool da run — e `game` só existe depois da montagem.
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Antes de qualquer sorteio: o `onLoad` dos dois pedestais de um par roda
    // em paralelo, e o jogador pode ter levado o item do irmão enquanto este
    // aqui ainda carregava. Sortear assim mesmo GASTARIA um item da pool da
    // run (`sortearItemEfeito` retira o que devolve) pra jogá-lo fora.
    if (!hasItem) return;

    final rng = Random();
    final jogo = game;
    final escolhida = familia ?? rng.nextInt(3);

    // ITEM_EFEITO é o único que consulta a pool: `sortearItemEfeito` já retira
    // o item, então a mesma run nunca oferece o mesmo duas vezes. Pool vazia
    // devolve `null` e a oferta recai nas outras duas famílias — pedestal
    // nenhum fica vazio por isso.
    if (escolhida == 0 && jogo is CreaturesRogueGame) {
      final item = jogo.sortearItemEfeito();
      if (item != null) {
        add(ItemEfeitoPickup(position: Vector2(8, -4), item: item));
        return;
      }
    }

    // Chegou aqui: ou a família é CONSUMÍVEL/UPGRADE, ou a pool de ITEM_EFEITO
    // acabou. Com irmão, cai na família que ele NÃO tem; sozinho, mantém o
    // cara-ou-coroa de sempre.
    final int familiaFinal;
    if (escolhida != 0) {
      familiaFinal = escolhida;
    } else if (familiaIrmao != null) {
      familiaFinal = familiaIrmao == 1 ? 2 : 1;
    } else {
      familiaFinal = rng.nextBool() ? 1 : 2;
    }

    if (familiaFinal == 1) {
      add(
        ConsumablePickup(
          position: Vector2(8, -4),
          tipo:
              ConsumableType.values[rng.nextInt(ConsumableType.values.length)],
        ),
      );
    } else {
      add(
        PowerUpItem(
          position: Vector2(8, -4),
          tipo: PowerUpType.values[rng.nextInt(PowerUpType.values.length)],
        ),
      );
    }
  }

  /// Vigia o próprio item pra avisar o [irmao] quando ele for levado.
  ///
  /// Por observação e não por callback, pela mesma razão que a sala de
  /// desafio observa o pedestal dela: o coletável nasce dentro de um `onLoad`
  /// assíncrono, e `Collectible.onCollect` pode devolver false (inventário
  /// cheio, vida já no topo) — aí o item CONTINUA no pedestal e a oferta não
  /// pode fechar. Observar a ausência acerta esse caso de graça; um gancho no
  /// toque teria que saber da recusa.
  @override
  void update(double dt) {
    super.update(dt);
    if (irmaos.isEmpty || !hasItem) return;

    if (children.whereType<Collectible>().isNotEmpty) {
      _itemApareceu = true;
      return;
    }
    if (!_itemApareceu) return;

    // O item daqui sumiu: o jogador escolheu. Fecha os dois lados — este
    // primeiro, pra que o `encerrarOferta` do irmão não volte batendo aqui.
    hasItem = false;
    for (final outro in irmaos) {
      outro.encerrarOferta();
    }
  }

  /// Tira o item daqui porque a escolha foi feita no outro pedestal.
  ///
  /// Idempotente e sem efeito colateral no irmão: é o que impede os dois
  /// lados de ficarem se avisando em círculo.
  void encerrarOferta() {
    if (!hasItem) return;
    hasItem = false;
    for (final coletavel in children.whereType<Collectible>().toList()) {
      coletavel.removeFromParent();
    }
  }
}
