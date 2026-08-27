import 'dart:math';
import 'dart:math' as math;
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
import 'package:creatures_rogue/game/components/map/stairs.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/map/wall_tile.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
import 'package:creatures_rogue/game/components/utils/y_sort.dart';
import 'dungeon_generator.dart';
import 'obstacle.dart';

class RoomComponent extends PositionComponent with HasGameRef {
  final RoomData data;
  final Player player;

  bool isLocked = false;
  List<Door> roomDoors = []; 
  List activeEnemies = []; 
  
  final Random _random = Random();
  
  static const double roomWidth = 16 * 12.0;
  static const double roomHeight = 16 * 12.0;
  static const double wallThickness = 16.0;
  static const double doorSize = 32.0;

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

  /// Quando não-nulo, esta sala de boss recebe O BOSS em vez de inimigos
  /// comuns. Quem constrói é o jogo (que também pendura a barra de vida na
  /// viewport da câmera) — a sala só precisa saber onde colocar e acompanhar
  /// a morte dele. Null = andar comum, sala de boss se comporta como antes.
  final Enemy? Function(Vector2 position)? bossBuilder;

  RoomComponent(
    this.data, {
    required this.player,
    int currentLevel = 1,
    this.floor = 1,
    this.bossBuilder,
  }) : super(
          size: Vector2(roomWidth, roomHeight),
          position: Vector2((data.x - 50) * roomWidth, (data.y - 50) * roomHeight),
          priority: _prioridadePiso,
        ) {
    theme = DungeonTheme.getThemeForLevel(currentLevel);
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
      ..colorFilter = const ColorFilter.mode(Palette.preto, BlendMode.srcATop); // Deixa a porta escura  
      
    _generateWalls();
    _generateFloorDetails();
    _generateDoors();

    if (data.type == RoomType.normal) {
      _generateObstacles();
    } else if (data.type == RoomType.item) {
      _spawnTreasure();
    } else if (data.type == RoomType.shop) {
      _spawnShop();
    }//else if (data.type == RoomType.start) {
    //  Enemy enemy = DummyEnemy(
    //    position: Vector2(width / 2, height / 2 - 32),
    //    playerTarget: player,
    //  );
    //  parent?.add(enemy);
    //}
  }

  void _spawnTreasure() {
    Vector2 centerPos = position + Vector2(width / 2, height / 2);

    // Sorteado entre TODOS os tipos: antes era `hpUp` fixo, então três dos
    // quatro upgrades nunca apareciam no jogo.
    final tipo = PowerUpType.values[_random.nextInt(PowerUpType.values.length)];

    parent?.add(PedestalComponent(
      position: centerPos,
      powerUpType: tipo,
    ));

    // Um item de uso único ao lado do pedestal — hoje é a única fonte deles,
    // porque a recompensa de sala limpa é só moeda ou cura. Se preferir que os
    // consumíveis venham só da loja, é esta chamada que sai.
    parent?.add(ConsumablePickup(
      position: centerPos + Vector2(28, 0),
      tipo: ConsumableType.values[_random.nextInt(ConsumableType.values.length)],
    ));
  }

  /// Três balcões, sempre nas mesmas posições: cura, um item de uso único e um
  /// upgrade permanente. Os dois últimos são sorteados por andar, então a loja
  /// não vende sempre a mesma coisa.
  ///
  /// Os preços são o botão de ajuste da economia: hoje uma sala limpa dá 1
  /// moeda e um andar tem ~10 salas de combate, ou seja, ~10 moedas por andar.
  void _spawnShop() {
    final centro = position + Vector2(width / 2, height / 2);

    final consumivel =
        ConsumableType.values[_random.nextInt(ConsumableType.values.length)];
    final upgrade =
        PowerUpType.values[_random.nextInt(PowerUpType.values.length)];

    parent?.add(ShopStand(
      position: centro + Vector2(-32, -8),
      preco: 4,
      spritePath: 'items/heart.png',
      cor1: Palette.vermelho,
      cor2: Palette.roxoEsc,
      // `heal` devolve false com a vida cheia — e é isso que evita cobrar por
      // uma cura que não curou.
      entregar: (p) => p.heal(4),
      msgFalha: 'VIDA CHEIA',
    ));

    parent?.add(ShopStand(
      position: centro + Vector2(0, -8),
      preco: 7,
      spritePath: consumivel.spritePath,
      cor1: consumivel.cor1,
      cor2: consumivel.cor2,
      entregar: (p) => p.addConsumable(consumivel),
    ));

    parent?.add(ShopStand(
      position: centro + Vector2(32, -8),
      preco: 14,
      spritePath: upgrade.spritePath,
      cor1: upgrade.cor1,
      cor2: upgrade.cor2,
      entregar: (p) {
        upgrade.aplicar(p);
        return true; // upgrade não tem como falhar
      },
    ));
  }

  /// Recompensa por limpar a sala: quase sempre uma moeda, raramente um
  /// coração. Nasce 28px abaixo do centro porque o centro já é ocupado — pelo
  /// pedestal na sala de tesouro e pela escada na sala de boss (a moeda em cima
  /// da escada seria coletada junto com a troca de andar, e sumiria).
  void _spawnRecompensa() {
    final pos = position + Vector2(width / 2, height / 2 + 28);

    // A chance de cura só é rolada com HP faltando: `heal()` devolve false com
    // a vida cheia, e aí o coração ficaria plantado no chão pra sempre no lugar
    // da moeda que o jogador teria levado.
    final podeCurar = player.currentHealth < player.maxHealth;

    if (podeCurar && _random.nextInt(100) < 12) {
      parent?.add(HeartPickup(position: pos));
    } else {
      parent?.add(CoinPickup(position: pos));
    }
  }

  void _generateFloorDetails() {
    for (double y = 16.0; y < height - 16.0; y += 16.0) {
      for (double x = 16.0; x < width - 16.0; x += 16.0) {
        
        int roll = _random.nextInt(100);

        if (roll < 45) {
          add(Grama(position: Vector2(x, y),cor1: theme.corClara,cor2: theme.corEscura,cor3: Palette.branco));
        } 
      }
    }
  }

  void _generateObstacles() {
    for (double y = 16.0; y < height - 16.0; y += 16.0) {
      for (double x = 16.0; x < width - 16.0; x += 16.0) {
        
        // REGRA 1: Não spawnar pedras bem no meio da sala
        //bool isCenter = (x >= width / 2 - 24 && x <= width / 2 + 8) && 
        //                (y >= height / 2 - 24 && y <= height / 2 + 8);
        //
        // REGRA 2: Não spawnar bloqueando o corredor das portas
        bool isDoorPathHorizontal = (y >= height / 2 - 16 && y <= height / 2 + 16);
        bool isDoorPathVertical = (x >= width / 2 - 16 && x <= width / 2 + 16);
        
        if (/*isCenter ||*/ isDoorPathHorizontal || isDoorPathVertical) {
          continue; 
        }

        int roll = _random.nextInt(100);

        if (roll < 5) {
          // Pedra bloqueia e tem altura visual: precisa entrar no Z-sort
          // global (mundo), senão desenha sempre atrás/na frente do jogador
          // inteiro, e não conforme quem está "mais pra baixo" na tela — por
          // isso vai pro `parent` (mundo) em vez de filha desta sala.
          final rockPos = position + Vector2(x, y);
          final rock = Rock(position: rockPos, cor1: theme.corClara, cor2: theme.corEscura);
          rock.priority = ySortPriority(rockPos.y + rock.size.y);
          _obstacleRects.add(Rect.fromLTWH(x, y, 16, 16));
          parent?.add(rock);
        } else if (roll >= 5 && roll < 8) {
          add(Hole(position: Vector2(x, y),cor1: theme.corClara,cor2: theme.corEscura,));
          _obstacleRects.add(Rect.fromLTWH(x, y, 16, 16));
        }
      }
    }
  }

  void _generateDoors() {
    bool initialOpen = data.isCleared || data.type == RoomType.start || !data.isVisited;
    void addDoorHalf(Vector2 pos, double rot, {bool flipX = false}) {
      var d = Door(
        position: pos,
        angleVal: 0,//rot,
        isOpen: initialOpen,
        flipX: false,//flipX,
        cor1: theme.corClara,  
        cor2: theme.corEscura,
        cor3: theme.corBranca,
      );
      roomDoors.add(d);
      add(d);
    }

    if (data.doorTop) {
      addDoorHalf(Vector2((width / 2) - 16, 0), math.pi/2, flipX: false);
      addDoorHalf(Vector2(width / 2, 0), math.pi/2, flipX: true);
    }
    if (data.doorBottom) {
      addDoorHalf(Vector2((width / 2) - 16, height - 16), -math.pi/2, flipX: true);
      addDoorHalf(Vector2(width / 2, height - 16), -math.pi/2, flipX: false);
    }
    if (data.doorLeft) {
      addDoorHalf(Vector2(0, (height / 2) - 16), 0, flipX: true);
      addDoorHalf(Vector2(0, height / 2), 0, flipX: false);
    }
    if (data.doorRight) {
      addDoorHalf(Vector2(width - 16, (height / 2) - 16), math.pi, flipX: false);
      addDoorHalf(Vector2(width - 16, height / 2), math.pi, flipX: true);
    }
  }

  void onPlayerEnter() {
    data.isVisited = true;
    if (!data.isCleared && data.type != RoomType.start) {
      _lockRoom();
      _spawnEnemies();
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
      parent?.add(Stairs(
        position: position + Vector2(width / 2, height / 2)
      ));
    }

    _spawnRecompensa();
  }

  void _spawnBoss(){
    final construirBoss = bossBuilder;
    if (construirBoss != null) {
      final boss = construirBoss(position + Vector2(width / 2, height / 2 - 24));
      if (boss != null) {
        activeEnemies.add(boss);
        parent?.add(boss);
      }
    }
  }

  void _spawnEnemies() {
    // Andar de boss: um adversário só, no centro, e nada de turma comum.
    // Entra em activeEnemies como qualquer inimigo, então a sala destranca
    // pela mesma regra de sempre — quando ele morre.

    if (floor % 5 == 0){
      _spawnBoss();
      return;
    }
    
    int count = 2 + _random.nextInt(3);
    
    for (int i = 0; i < count; i++) {
      double px = 0;
      double py = 0;
      bool validPosition = false;
      int attempts = 0; 

      while (!validPosition && attempts < 30) {
        px = 48 + _random.nextInt(6) * 16.0;
        py = 48 + _random.nextInt(6) * 16.0;

        Rect enemyRect = Rect.fromLTWH(px, py, 16, 16);
        // `_obstacleRects` (não `children`) porque a Rock foi reparentada pro
        // mundo pro Z-sort — checar `children` perderia essa colisão.
        validPosition = !_obstacleRects.any((r) => r.overlaps(enemyRect));
        attempts++;
      }

      Vector2 spawnPos = position + Vector2(px, py) + Vector2(8, 8);

      Enemy enemy = EnemySpawner.getRandomEnemy(spawnPos, player);
      
      activeEnemies.add(enemy);
      parent?.add(enemy); 
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (isLocked) {
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

    final String pathWall = 'tileset/arvore1.png';//'tileset/wall.png';       
    //final String pathCorner = 'tileset/arvore1.png';//'tileset/wallQuina.png'; 

    for (int y = 0; y < tilesY; y++) {
      for (int x = 0; x < tilesX; x++) {
        bool isTop = y == 0;
        bool isBottom = y == tilesY - 1;
        bool isLeft = x == 0;
        bool isRight = x == tilesX - 1;

        if (isTop || isBottom || isLeft || isRight) {
          
          bool isDoorTop = isTop && data.doorTop && (x >= (tilesX / 2) - 1 && x <= (tilesX / 2));
          bool isDoorBottom = isBottom && data.doorBottom && (x >= (tilesX / 2) - 1 && x <= (tilesX / 2));
          bool isDoorLeft = isLeft && data.doorLeft && (y >= (tilesY / 2) - 1 && y <= (tilesY / 2));
          bool isDoorRight = isRight && data.doorRight && (y >= (tilesY / 2) - 1 && y <= (tilesY / 2));

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
            add(WallTile(
              position: Vector2(x * tileSize, y * tileSize),
              spritePath: spriteToUse,
              angleVal: rotation,
              cor1: theme.corClara,   
              cor2: theme.corEscura,
              cor3: theme.corBranca,
            ));
          }
        }
      }
    }

    double midX = width / 2;
    double midY = height / 2;
    double doorSpan = 32.0;

    if (data.doorTop) {
      add(WallBarrier(position: Vector2(0, 0), size: Vector2(midX - (doorSpan / 2), 16)));
      add(WallBarrier(position: Vector2(midX + (doorSpan / 2), 0), size: Vector2(midX - (doorSpan / 2), 16)));
    } else {
      add(WallBarrier(position: Vector2(0, 0), size: Vector2(width, 16)));
    }

    if (data.doorBottom) {
      add(WallBarrier(position: Vector2(0, height - 16), size: Vector2(midX - (doorSpan / 2), 16)));
      add(WallBarrier(position: Vector2(midX + (doorSpan / 2), height - 16), size: Vector2(midX - (doorSpan / 2), 16)));
    } else {
      add(WallBarrier(position: Vector2(0, height - 16), size: Vector2(width, 16)));
    }

    if (data.doorLeft) {
      add(WallBarrier(position: Vector2(0, 0), size: Vector2(16, midY - (doorSpan / 2))));
      add(WallBarrier(position: Vector2(0, midY + (doorSpan / 2)), size: Vector2(16, midY - (doorSpan / 2))));
    } else {
      add(WallBarrier(position: Vector2(0, 0), size: Vector2(16, height)));
    }

    if (data.doorRight) {
      add(WallBarrier(position: Vector2(width - 16, 0), size: Vector2(16, midY - (doorSpan / 2))));
      add(WallBarrier(position: Vector2(width - 16, midY + (doorSpan / 2)), size: Vector2(16, midY - (doorSpan / 2))));
    } else {
      add(WallBarrier(position: Vector2(width - 16, 0), size: Vector2(16, height)));
    }
  }

  // Criado uma única vez (antes era um Paint novo por sala, por frame)
  late final Paint _roomBackgroundPaint = Paint()..color = Palette.branco;
  late final Rect _roomBackgroundRect = Rect.fromLTWH(0, 0, width, height);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(_roomBackgroundRect, _roomBackgroundPaint);

    super.render(canvas);
  }

  // --- CULLING: só a(s) sala(s) na tela gastam CPU/GPU ---
  // Sem isso, as 12 salas desenhavam ~44 tiles de parede cada uma
  // (~530 draw calls) e atualizavam toda a árvore de filhos por frame.
  CameraComponent? _camera;

  bool _isOnCamera() {
    final cam = _camera ?? CameraComponent.currentCamera;
    if (cam == null || !cam.isMounted) return true; // sem câmera ainda: não corta nada
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