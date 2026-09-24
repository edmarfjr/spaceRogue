import 'package:creatures_rogue/game/game_settings.dart';
import 'dart:math';
import 'package:creatures_rogue/game/components/items/item_efeito.dart';
import 'package:creatures_rogue/game/components/map/floor_text.dart';
import 'package:creatures_rogue/game/components/creatures/creature_registry.dart';
import 'package:creatures_rogue/game/components/effects/boss_cutscene.dart';
import 'package:creatures_rogue/game/creatures_rogue_game.dart';
import 'dart:math' as math;
import 'package:creatures_rogue/game/components/map/spike_trap.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/dungeon_theme.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/enemies/dummy_enemy.dart';
import 'package:creatures_rogue/game/components/enemies/enemy.dart';
import 'package:creatures_rogue/game/components/enemies/enemy_spawner.dart';
import 'package:creatures_rogue/game/components/items/coin_pickup.dart';
import 'package:creatures_rogue/game/components/items/consumable_item.dart';
import 'package:creatures_rogue/game/components/items/heart_pickup.dart';
import 'package:creatures_rogue/game/components/items/power_up_item.dart';
import 'package:creatures_rogue/game/components/items/shop_stand.dart';
import 'package:creatures_rogue/game/components/map/door.dart';
import 'package:creatures_rogue/game/components/map/pedestal.dart';
import 'package:creatures_rogue/game/components/creatures/wild_creature_npc.dart';
import 'package:creatures_rogue/game/components/map/stairs.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/map/wall_tile.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/utils/y_sort.dart';
import 'package:creatures_rogue/l10n/l10n_extensions.dart';
import 'dungeon_generator.dart';
import 'obstacle.dart';

/// Um dos quatro lados de uma sala. Usado pra descrever por onde alguém
/// entrou ou saiu, sem espalhar comparações de coordenada pelo código.
enum LadoSala {
  topo,
  direita,
  baixo,
  esquerda;

  LadoSala get oposto => switch (this) {
    LadoSala.topo => LadoSala.baixo,
    LadoSala.baixo => LadoSala.topo,
    LadoSala.esquerda => LadoSala.direita,
    LadoSala.direita => LadoSala.esquerda,
  };

  /// Gira 90° no sentido do relógio: topo → direita → baixo → esquerda.
  ///
  /// Sentido fixo em vez de sorteado: a cena do boss usa isto pra escolher por
  /// onde o treinador sai, e um sorteio ali deixaria a cena diferente a cada
  /// entrada sem o jogador entender por quê.
  LadoSala get perpendicular => switch (this) {
    LadoSala.topo => LadoSala.direita,
    LadoSala.direita => LadoSala.baixo,
    LadoSala.baixo => LadoSala.esquerda,
    LadoSala.esquerda => LadoSala.topo,
  };
}

class RoomComponent extends PositionComponent with HasGameRef {
  final RoomData data;
  final Player player;

  bool isLocked = false;

  /// Cena de abertura do boss rodando agora. Enquanto isso for true, a
  /// checagem de "sala limpa" fica suspensa — o boss só nasce no meio da cena,
  /// e sem essa guarda a sala se destrancaria no primeiro quadro (ver
  /// [update]), abrindo a porta e nascendo escada e recompensa antes de
  /// existir adversário.
  bool cutsceneAtiva = false;

  /// Uma vez por visita: sair e voltar não repete a cena. Morrer é run nova,
  /// com sala nova, então lá ela toca de novo — que é o desejado.
  bool _cutsceneBossJaRodou = false;
  List<Door> roomDoors = [];
  List activeEnemies = [];

  final Random _random = Random();

  static const double roomWidth = 16 * 12.0;
  static const double roomHeight = 16 * 12.0;
  static const double wallThickness = 16.0;
  static const double doorSize = 32.0;

  /// Faixa reservada pra HUD no topo — a linha 0 de tiles (16px). Room em si
  /// não cresce (a câmera é `withFixedResolution(roomWidth, roomHeight)`, e o
  /// stride da grade de salas usa `roomHeight` também — crescer quebraria os
  /// dois); a área jogável é que encolhe uma linha, de 10×10 pra 10×9 tiles.
  /// Linha 0 fica sem parede/piso/colisão nenhuma — só fundo vazio, pra HUD
  /// desenhar em cima sem disputar espaço com sprite de sala.
  static const double topoHud = 16.0;

  /// Centro vertical da área JOGÁVEL (linhas 1-11, y de 16 a 192) — usado
  /// onde antes era `height / 2`, pra tudo que precisa ficar centralizado no
  /// que sobrou depois da faixa da HUD (portas, obstáculos, spawns...).
  /// `midX`/`width / 2` continuam valendo — só o eixo vertical mudou.
  static const double centerY = (topoHud + roomHeight) / 2;

  /// Piso/paredes/grama ficam SEMPRE atrás de qualquer ator ou obstáculo
  /// Y-sorted — inclusive nas salas ao norte da origem, onde a coordenada Y
  /// dos atores fica negativa. Um valor bem abaixo de qualquer Y de mundo
  /// possível garante isso sem depender de onde a sala está na grade.
  static const int _prioridadePiso = -1000000;

  /// Retângulos locais (mesmo espaço de `px, py` usado em [_spawnEnemies]) de
  /// cada obstáculo gerado, pra checar sobreposição no spawn de inimigo —
  /// funciona independente de o obstáculo continuar filho desta sala (Hole)
  /// ou ter sido reparentado pro mundo pra entrar no Z-sort global (Rock).
  final List<Rect> _obstacleRects = [];

  //late final Sprite floorSprite;
  //late final Sprite doorSprite;

  late final DungeonTheme theme;
  final int floor;
  final int dungeon;

  /// Quando não-nulo, esta sala de boss recebe O BOSS em vez de inimigos
  /// comuns. Quem constrói é o jogo (que também pendura a barra de vida na
  /// viewport da câmera) — a sala só precisa saber onde colocar e acompanhar
  /// a morte dele. Null = andar comum, sala de boss se comporta como antes.
  final Enemy? Function(Vector2 position)? bossBuilder;

  /// Criatura selvagem da sala da escada do quarto andar (ver
  /// PIVOT_CONTROLE_DIRETO.md §5) — mesmo padrão do `bossBuilder` acima: quem
  /// decide QUANDO e SE nasce é o jogo (que sabe se há slot livre no grupo),
  /// a sala só sabe onde colocar. `null` = andar comum, sem criatura nenhuma.
  final WildCreatureNpc? Function(Vector2 position)? wildCreatureBuilder;

  RoomComponent(
    this.data, {
    required this.player,
    this.floor = 1,
    this.dungeon = 1,
    this.bossBuilder,
    this.wildCreatureBuilder,
  }) : super(
         size: Vector2(roomWidth, roomHeight),
         position: Vector2(
           (data.x - dungeonGridOrigin) * roomWidth,
           (data.y - dungeonGridOrigin) * roomHeight,
         ),
         priority: _prioridadePiso,
       ) {
    theme = DungeonTheme.getThemeForLevel(dungeon);
  }

  late final Paint floorPaint;
  late final Paint doorPaint;
  late final Paint lockedDoorPaint;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    //  floorSprite = await gameRef.loadSprite('tileset/floor.png');
    //  doorSprite = await gameRef.loadSprite('tileset/door1.png');

    floorPaint = Paint()
      ..filterQuality = FilterQuality.none
      ..colorFilter = ColorFilter.mode(Palette.cinza, BlendMode.modulate);

    doorPaint = Paint()
      ..filterQuality = FilterQuality.none
      ..colorFilter = ColorFilter.mode(Palette.cinzaEsc, BlendMode.modulate);

    lockedDoorPaint = Paint()
      ..filterQuality = FilterQuality.none
      ..colorFilter = const ColorFilter.mode(
        Palette.preto,
        BlendMode.srcATop,
      ); // Deixa a porta escura

    _generateWalls();
    _generateFloorDetails();
    _generateDoors();

    if (data.type == RoomType.normal) {
      _generateObstacles();
    } else if (data.type == RoomType.item) {
      _spawnTreasure();
    } else if (data.type == RoomType.shop) {
      _spawnShop();
    } else if (data.type == RoomType.start) {
      if (dungeon == 1 && floor ==1) {
        _spawnTutorial();
      //  _spawnSalaDeTeste();
      }
    }
  }

  /// Tutorial no chão da sala inicial. Filho DESTA sala de propósito: é o que
  /// coloca o texto acima do piso e abaixo dos atores sem escolher prioridade
  /// na mão (ver [FloorText]).
  void _spawnTutorial() {
    final contexto = game.buildContext;
    if (contexto == null) return;

    add(
      FloorText(
        // Sem controle na tela o jogador esta no teclado (ver
        // `Player.onKeyEvent`), e mandar ele arrastar o dedo seria instrucao
        // pra um controle que nem esta montado.
        texto: GameSettings.instance.controlesNaTela
            ? contexto.l10n.tutorial_controles
            : contexto.l10n.tutorial_controlesTeclado,
        position: Vector2(width / 2, centerY + 44),
        
      ),
    );
  }

  void _spawnSalaDeTeste() {
    final candidatas = CreatureRegistry.all
        .where((c) => c.evoluir != null && c.id != player.creatureData.id)
        .take(2)
        .toList();

    for (var i = 0; i < candidatas.length; i++) {
      parent?.add(
        WildCreatureNpc(
          position: position + Vector2(width / 2 - 24 + i * 48, centerY - 32),
          creatureData: candidatas[i],
        ),
      );
    }
    /*
    for (var i = 0; i < 4; i++) {
      parent?.add(
        ConsumablePickup(
          position: position + Vector2(width / 2 - 24 + i * 16, centerY + 24),
          tipo: ConsumableType.doce,
        ),
      );
    }
    */
    parent?.add(ItemEfeitoPickup(position: Vector2(width / 2 - 24, centerY + 24), item: Bussola()));
    parent?.add(ItemEfeitoPickup(position: Vector2(width / 2 + 24, centerY + 24), item: EloDoGrupo()));
      Enemy enemy = DummyEnemy(
        position: Vector2(width / 2, height / 2 - 32),
        playerTarget: player,
      );
      parent?.add(enemy);
      
  }

  void _spawnTreasure({double offsetX = 0,double offsetY = 0}) {
    Vector2 centerPos = position + Vector2(width / 2 - 8, centerY) + Vector2(offsetX,offsetY);

    // O pedestal sorteia sozinho entre UPGRADE, CONSUMÍVEL e ITEM_EFEITO —
    // ver `PedestalComponent.onLoad`, que é onde a pool da run fica acessível.
    parent?.add(PedestalComponent(position: centerPos));

  }

  /// Três balcões, sempre nas mesmas posições: cura, um item de uso único e um
  /// upgrade permanente. Os dois últimos são sorteados por andar, então a loja
  /// não vende sempre a mesma coisa.
  ///
  /// Os preços são o botão de ajuste da economia: hoje uma sala limpa dá 1
  /// moeda e um andar tem ~10 salas de combate, ou seja, ~10 moedas por andar.
  void _spawnShop() {
    final centro = position + Vector2(width / 2, centerY);

    final consumivel =
        ConsumableType.values[_random.nextInt(ConsumableType.values.length)];
    final upgrade =
        PowerUpType.values[_random.nextInt(PowerUpType.values.length)];

    // A terceira bancada é meio a meio entre upgrade de stat e item com
    // gatilho. Ao contrário do pedestal, a loja só ESPIA a pool — o item sai
    // dela na hora da compra (ver `entregar` abaixo). Expor não gasta: uma
    // loja que o jogador não tem moeda pra pagar deixa o item disponível pro
    // resto da run.
    final jogo = game;
    final itemEfeito = _random.nextBool() && jogo is CreaturesRogueGame
        ? jogo.espiarItemEfeito()
        : null;

    parent?.add(
      ShopStand(
        position: centro + Vector2(-32, -8),
        preco: 4,
        spritePath: 'items/fruta.png',
        cor1: Palette.laranja,
        cor2: Palette.verdeEsc,
        // `heal` devolve false com a vida cheia — e é isso que evita cobrar por
        // uma cura que não curou.
        entregar: (p) => p.heal(1),
        msgFalha: game.buildContext!.l10n.effect_vidaCheia,
        descricao: (context) => context.l10n.effect_maisVida(1),
      ),
    );

    parent?.add(
      ShopStand(
        position: centro + Vector2(0, -8),
        preco: 7,
        spritePath: consumivel.spritePath,
        cor1: consumivel.cor1,
        cor2: consumivel.cor2,
        entregar: (p) => p.addConsumable(consumivel),
        descricao: consumivel.descricao,
      ),
    );

    parent?.add(
      itemEfeito != null
          // Mais caro que o upgrade de stat: muda como se joga, e a run só
          // oferece cada um uma vez.
          ? ShopStand(
              position: centro + Vector2(32, -8),
              preco: 20,
              spritePath: itemEfeito.spritePath,
              cor1: itemEfeito.cor1,
              cor2: itemEfeito.cor2,
              entregar: (p) {
                // `consumirItemEfeito` devolve false se um pedestal entregou
                // o mesmo item enquanto a loja o exibia. Recusar aqui é o que
                // impede duas cópias na lista — e, como `ShopStand` só cobra
                // quando `entregar` devolve true, o jogador não paga por nada.
                final jogo = game;
                if (jogo is! CreaturesRogueGame) return false;
                if (!jogo.consumirItemEfeito(itemEfeito)) return false;
                p.itens.add(itemEfeito);
                return true;
              },
              msgFalha: game.buildContext!.l10n.effect_jaTemItem,
              descricao: itemEfeito.descricao,
            )
          : ShopStand(
              position: centro + Vector2(32, -8),
              preco: 14,
              spritePath: upgrade.spritePath,
              cor1: upgrade.cor1,
              cor2: upgrade.cor2,
              entregar: (p) {
                upgrade.aplicar(p);
                return true; // upgrade não tem como falhar
              },
              descricao: upgrade.descricao,
            ),
    );
  }

  void _spawnRecompensa() {
    final pos = position + Vector2(width / 2, centerY + 24);

    //final podeCurar = player.currentHealth < player.maxHealth;
    final recompensaChance = _random.nextInt(100);
    if (recompensaChance < 12) {
      parent?.add(HeartPickup(position: pos));
    } else if (recompensaChance >= 12 && recompensaChance < 40){
      parent?.add(CoinPickup(position: pos));
    }
  }

  void _generateFloorDetails() {
    // Linha 1 (y=16) agora é parede (ver `_generateWalls`) — piso começa na
    // linha 2.
    for (double y = topoHud + 16.0; y < height - 16.0; y += 16.0) {
      for (double x = 16.0; x < width - 16.0; x += 16.0) {
        int roll = _random.nextInt(100);

        if (dungeon == 2 || dungeon == 4) {
          add(
            ChaoCave(
              position: Vector2(x, y),
              cor1: theme.corClara,
              cor2: theme.corEscura,
              cor3: theme.corBranca,
            ),
          );
        } else {
          if (roll < 45) {
            add(
              Grama(
                position: Vector2(x, y),
                cor1: theme.corClara,
                cor2: theme.corEscura,
                cor3: theme.corBranca,
              ),
            );
          }
        }
      }
    }
  }

  void _generateObstacles() {
    for (double y = topoHud + 16.0; y < height - 16.0; y += 16.0) {
      for (double x = 16.0; x < width - 16.0; x += 16.0) {
        // REGRA 1: Não spawnar pedras bem no meio da sala
        //bool isCenter = (x >= width / 2 - 24 && x <= width / 2 + 8) &&
        //                (y >= height / 2 - 24 && y <= height / 2 + 8);
        //
        // REGRA 2: Não spawnar bloqueando o corredor das portas
        bool isDoorPathHorizontal =
            (y >= height / 2 - 16 && y <= height / 2 + 16);
        bool isDoorPathVertical = (x >= width / 2 - 16 && x <= width / 2 + 16);

        if ( /*isCenter ||*/ isDoorPathHorizontal || isDoorPathVertical) {
          continue;
        }

        int roll = _random.nextInt(100);

        if (roll < 5) {
          // Pedra bloqueia e tem altura visual: precisa entrar no Z-sort
          // global (mundo), senão desenha sempre atrás/na frente do jogador
          // inteiro, e não conforme quem está "mais pra baixo" na tela — por
          // isso vai pro `parent` (mundo) em vez de filha desta sala.
          final rockPos = position + Vector2(x, y);
          final rock = Rock(
            position: rockPos,
            cor1: theme.corClara,
            cor2: theme.corEscura,
            cor3: theme.corBranca,
          );
          rock.priority = ySortPriority(rockPos.y + rock.size.y);
          _obstacleRects.add(Rect.fromLTWH(x, y, 16, 16));
          parent?.add(rock);
        } else if (roll >= 5 && roll < 8) {
          add(
            Hole(
              position: Vector2(x, y),
              cor1: theme.corClara,
              cor2: theme.corEscura,
              cor3: theme.corBranca,
            ),
          );
          _obstacleRects.add(Rect.fromLTWH(x, y, 16, 16));
        } else if (roll >= 8 && roll < 15) {
          if(dungeon == 2 || dungeon == 4){
            add(
            Cogumelos(
              position: Vector2(x, y),
              cor1: theme.corClara,
              cor2: theme.corEscura,
              cor3: theme.corBranca,
            ),);
          }else{
            add(GramaAlta(position: Vector2(x, y),cor1: theme.corClara,cor2: theme.corEscura,cor3: theme.corBranca));
          }
          _obstacleRects.add(Rect.fromLTWH(x, y, 16, 16));
        } else if (roll >= 15 && roll < 18) {
          add(
            SpikeTrap(
              position: Vector2(x, y),
              cor1: theme.corClara,
              cor2: theme.corEscura,
            ),
          );
          _obstacleRects.add(Rect.fromLTWH(x, y, 16, 16));
        }
      }
    }
  }

  void _generateDoors() {
    bool initialOpen =
        data.isCleared || data.type == RoomType.start || !data.isVisited;
    void addDoorHalf(Vector2 pos, double rot, {bool flipX = false}) {
      var spritePath = 'tileset/arvore2.png';
      if (dungeon == 2 || dungeon == 4) spritePath = 'tileset/pedraCave2.png';
      var d = Door(
        position: pos,
        angleVal: 0, //rot,
        isOpen: initialOpen,
        flipX: false, //flipX,
        cor1: theme.corClara,
        cor2: theme.corEscura,
        cor3: theme.corBranca,
        cor4: theme.corChao,
        spritePath: spritePath,
      );
      roomDoors.add(d);
      add(d);
    }

    if (data.doorTop) {
      addDoorHalf(
        Vector2((width / 2) - 16, topoHud),
        math.pi / 2,
        flipX: false,
      );
      addDoorHalf(Vector2(width / 2, topoHud), math.pi / 2, flipX: true);
    }
    if (data.doorBottom) {
      addDoorHalf(
        Vector2((width / 2) - 16, height - 16),
        -math.pi / 2,
        flipX: true,
      );
      addDoorHalf(Vector2(width / 2, height - 16), -math.pi / 2, flipX: false);
    }
    if (data.doorLeft) {
      addDoorHalf(Vector2(0, (height / 2) - 16), 0, flipX: true);
      addDoorHalf(Vector2(0, height / 2), 0, flipX: false);
    }
    if (data.doorRight) {
      addDoorHalf(
        Vector2(width - 16, (height / 2) - 16),
        math.pi,
        flipX: false,
      );
      addDoorHalf(Vector2(width - 16, height / 2), math.pi, flipX: true);
    }
  }

  /// [ladoEntrada] é a porta POR ONDE o jogador entrou nesta sala — usada pela
  /// cena do boss pra montar a coreografia em relação a ele.
  void onPlayerEnter(LadoSala ladoEntrada) {
    data.isVisited = true;
    if (!data.isCleared && (data.type == RoomType.normal || data.type == RoomType.boss)) {
      _lockRoom();
      _spawnEnemies(ladoEntrada);
    }
  }

  void _lockRoom() {
    isLocked = true;
    for (var door in roomDoors) {
      door.close();
    }
  }

  void _unlockRoom() {
    isLocked = false;
    data.isCleared = true;

    for (var door in roomDoors) {
      door.open();
    }

    if (data.type == RoomType.boss) {
      final posList = [Vector2(-24,-24),Vector2(-8,-24),Vector2(8,-24),
      Vector2(-24,-8),Vector2(8,-8)];

      for (var pos in posList){
        final rockPos = position + Vector2(width / 2, centerY) + pos;
        final rock = Rock(
          position: rockPos,
          cor1: theme.corClara,
          cor2: theme.corEscura,
          cor3: theme.corBranca,
        );
        rock.priority = ySortPriority(rockPos.y + rock.size.y);
        _obstacleRects.add(Rect.fromLTWH(x, y, 16, 16));
        parent?.add(rock);
      }

      parent?.add(Stairs(position: position + Vector2(width / 2, centerY)));

      final construirCriatura = wildCreatureBuilder;
      if (construirCriatura != null) {
        // Posição própria (centerY - 28), livre da escada (centerY) e da
        // recompensa (centerY + 28) — ver PIVOT_CONTROLE_DIRETO.md §5.2.
        final npc = construirCriatura(
          position + Vector2(width / 2, centerY - 64),
        );
        if (npc != null) parent?.add(npc);
      }
      return;
    }

    _spawnRecompensa();
  }

  /// Ponto logo DENTRO da parede de [lado], em coordenadas locais. A parede
  /// tem 16px, e o topo perde outros 16 pra HUD (ver [topoHud]).
  Vector2 _pontoNaBorda(LadoSala lado) => switch (lado) {
    LadoSala.topo => Vector2(width / 2, topoHud + 16 + 8),
    LadoSala.baixo => Vector2(width / 2, height - 16 - 8),
    LadoSala.esquerda => Vector2(16 + 8, centerY),
    LadoSala.direita => Vector2(width - 16 - 8, centerY),
  };

  static const double _afastamentoBoss = 24.0;

  Vector2 _afastamento(LadoSala lado) => switch (lado) {
    LadoSala.topo => Vector2(0, -_afastamentoBoss),
    LadoSala.baixo => Vector2(0, _afastamentoBoss),
    LadoSala.esquerda => Vector2(-_afastamentoBoss, 0),
    LadoSala.direita => Vector2(_afastamentoBoss, 0),
  };

  /// A cena segura o controle do jogador e a checagem de sala limpa; o boss
  /// nasce no meio dela, pelas mãos do treinador.
  ///
  /// A coreografia é toda relativa a [ladoJogador], a porta por onde o jogador
  /// entrou: o treinador vem pelo lado OPOSTO (encara o jogador em vez de
  /// nascer às costas dele), o boss nasce ainda mais além, do mesmo lado de
  /// onde o treinador veio (ou seja, oposto ao jogador), e a saída é
  /// PERPENDICULAR à entrada — sair de volta pela porta de onde veio leria
  /// como desistência, e sair pela porta do jogador o faria atravessá-lo.
  void _iniciarCutsceneBoss(LadoSala ladoJogador) {
    cutsceneAtiva = true;
    player.emCutscene = true;

    final ladoTreinador = ladoJogador.oposto;
    final centro = Vector2(width / 2, centerY);
    final posBoss = centro + _afastamento(ladoTreinador);

    add(
      BossCutscene(
        entrada: _pontoNaBorda(ladoTreinador),
        centro: centro,
        saida: _pontoNaBorda(ladoTreinador.perpendicular),
        posBoss: posBoss,
        aoInvocar: () => _spawnBoss(posBoss),
        aoTerminar: () {
          cutsceneAtiva = false;
          player.emCutscene = false;
          for (final inimigo in activeEnemies) {
            if (inimigo is Enemy) inimigo.emCutscene = false;
          }
        },
      ),
    );
  }

  /// [posLocal] nulo = posição padrão (acima do centro), usada quando não há
  /// cena de abertura pra escolher o lado.
  void _spawnBoss([Vector2? posLocal]) {
    final construirBoss = bossBuilder;
    if (construirBoss != null) {
      final boss = construirBoss(
        position + (posLocal ?? Vector2(width / 2, centerY - _afastamentoBoss)),
      );
      if (boss != null) {
        // Nasce inerte se a cena ainda está rodando: ele aparece na invocação
        // mas só age quando o treinador sai. Derivado de `cutsceneAtiva` em
        // vez de um parâmetro — quem chama fora da cena não precisa saber
        // que isso existe.
        boss.emCutscene = cutsceneAtiva;
        activeEnemies.add(boss);
        parent?.add(boss);
      }
    }
  }

  void _spawnEnemies(LadoSala ladoEntrada) {
    // Sala final (RoomType.boss, onde a escada nasce): nunca turma comum. Só
    // spawna adversário de verdade no andar de boss (`bossBuilder` não nulo);
    // nos outros andares essa sala fica vazia e destranca na hora, sem briga.
    // Sem esse desvio por tipo de sala, o `floor % 5 == 0` de baixo valia pra
    // QUALQUER sala do andar — no andar de boss, até a loja spawnava boss.
    if (data.type == RoomType.boss) {
      if (bossBuilder != null && !_cutsceneBossJaRodou) {
        _cutsceneBossJaRodou = true;
        _iniciarCutsceneBoss(ladoEntrada);
      } else {
        // Sem boss neste andar (`bossBuilder` nulo) a sala destranca na hora,
        // e aí não há cena nenhuma pra abrir.
        _spawnBoss();
      }
      return;
    }

    int count = floor + _random.nextInt(3);
    //int count = floor + 1;

    for (int i = 0; i < count; i++) {
      double px = 0;
      double py = 0;
      bool validPosition = false;
      int attempts = 0;

      while (!validPosition && attempts < 30) {
        px = 64 + _random.nextInt(4) * 16.0;
        py = 64 + _random.nextInt(4) * 16.0;

        Rect enemyRect = Rect.fromLTWH(px, py, 16, 16);
        // `_obstacleRects` (não `children`) porque a Rock foi reparentada pro
        // mundo pro Z-sort — checar `children` perderia essa colisão.
        validPosition = !_obstacleRects.any((r) => r.overlaps(enemyRect));
        attempts++;
      }

      Vector2 spawnPos = position + Vector2(px, py) + Vector2(8, 8);

      Enemy enemy = EnemySpawner.getRandomEnemy(spawnPos, player, dungeon);

      activeEnemies.add(enemy);
      parent?.add(enemy);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isLocked && !cutsceneAtiva) {
      activeEnemies.removeWhere((enemy) => enemy.isRemoved);

      if (activeEnemies.isEmpty) {
        _unlockRoom();
      }
    }
  }

  void _generateWalls() {
    final double tileSize = 16.0;
    final int tilesX = (width / tileSize).round();
    final int tilesY = (height / tileSize).round();

    String pathWall = 'tileset/arvore1.png'; //'tileset/wall.png';
    //final String pathCorner = 'tileset/arvore1.png';//'tileset/wallQuina.png';
    if (dungeon == 2 || dungeon == 4) {
      pathWall = 'tileset/pedraCave.png';
    }

    // Linha 0 fica de fora — reservada pra HUD (ver `topoHud`), sem parede
    // nem piso ali. A parede "de cima" vira a linha 1.
    for (int y = 1; y < tilesY; y++) {
      for (int x = 0; x < tilesX; x++) {
        bool isTop = y == 1;
        bool isBottom = y == tilesY - 1;
        bool isLeft = x == 0;
        bool isRight = x == tilesX - 1;

        if (isTop || isBottom || isLeft || isRight) {
          bool isDoorTop =
              isTop &&
              data.doorTop &&
              (x >= (tilesX / 2) - 1 && x <= (tilesX / 2));
          bool isDoorBottom =
              isBottom &&
              data.doorBottom &&
              (x >= (tilesX / 2) - 1 && x <= (tilesX / 2));
          bool isDoorLeft =
              isLeft &&
              data.doorLeft &&
              (y >= (tilesY / 2) - 1 && y <= (tilesY / 2));
          bool isDoorRight =
              isRight &&
              data.doorRight &&
              (y >= (tilesY / 2) - 1 && y <= (tilesY / 2));

          if (isDoorTop || isDoorBottom || isDoorLeft || isDoorRight) {
            continue;
          }

          String spriteToUse = pathWall;
          double rotation = 0.0;

          /*
          if (isTop && isLeft)        { spriteToUse = pathCorner; rotation = 0; }
          else if (isTop && isRight)    { spriteToUse = pathCorner; rotation = math.pi / 2; }
          else if (isBottom && isRight) { spriteToUse = pathCorner; rotation = math.pi; }
          else if (isBottom && isLeft)  { spriteToUse = pathCorner; rotation = 3 * math.pi / 2; }
          else if (isTop)    { spriteToUse = pathWall; rotation = math.pi / 2; }
          else if (isBottom) { spriteToUse = pathWall; rotation = 3 * math.pi / 2; }
          else if (isLeft)   { spriteToUse = pathWall; rotation = 0; }
          else if (isRight)  { spriteToUse = pathWall; rotation = math.pi; }
          */

          if (spriteToUse.isNotEmpty) {
            add(
              WallTile(
                position: Vector2(x * tileSize, y * tileSize),
                spritePath: spriteToUse,
                angleVal: rotation,
                cor1: theme.corClara,
                cor2: theme.corEscura,
                cor3: theme.corBranca,
              ),
            );
          }
        }
      }
    }

    double midX = width / 2;
    double midY = height / 2;
    double doorSpan = 32.0;

    // Parede "de cima" agora fica na linha 1 (`topoHud`) — linha 0 é a faixa
    // reservada pra HUD, sem barreira nenhuma ali.
    if (data.doorTop) {
      add(
        WallBarrier(
          position: Vector2(0, topoHud),
          size: Vector2(midX - (doorSpan / 2), 16),
        ),
      );
      add(
        WallBarrier(
          position: Vector2(midX + (doorSpan / 2), topoHud),
          size: Vector2(midX - (doorSpan / 2), 16),
        ),
      );
    } else {
      add(
        WallBarrier(
          position: Vector2(0, topoHud),
          size: Vector2(width, 16),
        ),
      );
    }

    if (data.doorBottom) {
      add(
        WallBarrier(
          position: Vector2(0, height - 16),
          size: Vector2(midX - (doorSpan / 2), 16),
        ),
      );
      add(
        WallBarrier(
          position: Vector2(midX + (doorSpan / 2), height - 16),
          size: Vector2(midX - (doorSpan / 2), 16),
        ),
      );
    } else {
      add(
        WallBarrier(
          position: Vector2(0, height - 16),
          size: Vector2(width, 16),
        ),
      );
    }

    // Segmento de cima das barreiras laterais também para na linha 1 (não em
    // 0) — o de baixo do vão da porta não muda, já fica bem abaixo da faixa
    // reservada.
    if (data.doorLeft) {
      add(
        WallBarrier(
          position: Vector2(0, topoHud),
          size: Vector2(16, midY - (doorSpan / 2) - topoHud),
        ),
      );
      add(
        WallBarrier(
          position: Vector2(0, midY + (doorSpan / 2)),
          size: Vector2(16, midY - (doorSpan / 2)),
        ),
      );
    } else {
      add(
        WallBarrier(
          position: Vector2(0, topoHud),
          size: Vector2(16, height - topoHud),
        ),
      );
    }

    if (data.doorRight) {
      add(
        WallBarrier(
          position: Vector2(width - 16, topoHud),
          size: Vector2(16, midY - (doorSpan / 2) - topoHud),
        ),
      );
      add(
        WallBarrier(
          position: Vector2(width - 16, midY + (doorSpan / 2)),
          size: Vector2(16, midY - (doorSpan / 2)),
        ),
      );
    } else {
      add(
        WallBarrier(
          position: Vector2(width - 16, topoHud),
          size: Vector2(16, height - topoHud),
        ),
      );
    }
  }

  // Criado uma única vez (antes era um Paint novo por sala, por frame)
  //late final Paint _roomBackgroundPaint = Paint()..color = Palette.branco;
  // Começa em `topoHud`, não 0 — senão a cor de chão pinta por baixo da HUD
  // a faixa que devia ficar vazia.
  late final Rect _roomBackgroundRect = Rect.fromLTWH(
    0,
    topoHud,
    width,
    height - topoHud,
  );

  @override
  void render(Canvas canvas) {
    canvas.drawRect(_roomBackgroundRect, Paint()..color = theme.corChao);
    //canvas.drawRect(Rect.fromLTWH(64, 64, 16*4, 16*4), Paint()..color = Palette.vermelho..style = PaintingStyle.stroke);

    super.render(canvas);
  }

  CameraComponent? _camera;

  bool _isOnCamera() {
    final cam = _camera ?? CameraComponent.currentCamera;
    if (cam == null || !cam.isMounted)
      return true; // sem câmera ainda: não corta nada
    _camera = cam;
    return cam.visibleWorldRect.overlaps(toAbsoluteRect());
  }

  @override
  void updateTree(double dt) {
    if (!_isOnCamera()) return;
    super.updateTree(dt);
  }

  @override
  void renderTree(Canvas canvas) {
    if (!_isOnCamera()) return;
    super.renderTree(canvas);
  }
}
