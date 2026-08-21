import 'dart:math';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:creatures_rogue/game/components/core/dungeon_theme.dart';
import 'package:creatures_rogue/game/components/core/palette.dart';
import 'package:creatures_rogue/game/components/enemies/dummy_enemy.dart';
import 'package:creatures_rogue/game/components/enemies/enemy.dart';
import 'package:creatures_rogue/game/components/enemies/enemy_spawner.dart';
import 'package:creatures_rogue/game/components/items/power_up_item.dart';
import 'package:creatures_rogue/game/components/map/door.dart';
import 'package:creatures_rogue/game/components/map/pedestal.dart';
import 'package:creatures_rogue/game/components/map/stairs.dart';
import 'package:creatures_rogue/game/components/map/wall_barrier.dart';
import 'package:creatures_rogue/game/components/map/wall_tile.dart';
import 'package:creatures_rogue/game/components/player/player.dart';
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

  //late final Sprite floorSprite;
  //late final Sprite doorSprite;

  late final DungeonTheme theme;

  /// Quando não-nulo, esta sala de boss recebe O BOSS em vez de inimigos
  /// comuns. Quem constrói é o jogo (que também pendura a barra de vida na
  /// viewport da câmera) — a sala só precisa saber onde colocar e acompanhar
  /// a morte dele. Null = andar comum, sala de boss se comporta como antes.
  final Enemy? Function(Vector2 position)? bossBuilder;

  RoomComponent(
    this.data, {
    required this.player,
    int currentLevel = 1,
    this.bossBuilder,
  }) : super(
          size: Vector2(roomWidth, roomHeight),
          position: Vector2((data.x - 50) * roomWidth, (data.y - 50) * roomHeight),
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
    _generateDoors();

    if (data.type == RoomType.normal) {
      _generateObstacles();
    } else if (data.type == RoomType.item) {
      _spawnTreasure();
    }else if (data.type == RoomType.start) {
      Enemy enemy = DummyEnemy(
        position: Vector2(width / 2, height / 2 - 32),
        playerTarget: player,
      );
      parent?.add(enemy);
    }
  }

  void _spawnTreasure() {
    Vector2 centerPos = position + Vector2(width / 2, height / 2);
    
    parent?.add(PedestalComponent(
      position: centerPos,
      powerUpType: PowerUpType.hpUp, 
    ));
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
          add(Rock(position: Vector2(x, y),cor1: theme.corClara,cor2: theme.corEscura,));
        } else if (roll >= 5 && roll < 8) {
          add(Hole(position: Vector2(x, y)));
        }
      }
    }
  }

  void _generateDoors() {
    bool initialOpen = data.isCleared || data.type == RoomType.start || !data.isVisited;
    void addDoorHalf(Vector2 pos, double rot, {bool flipX = false}) {
      var d = Door(
        position: pos,
        angleVal: rot,
        isOpen: initialOpen,
        flipX: flipX,
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
  }

  void _spawnEnemies() {
    // Andar de boss: um adversário só, no centro, e nada de turma comum.
    // Entra em activeEnemies como qualquer inimigo, então a sala destranca
    // pela mesma regra de sempre — quando ele morre.
    final construirBoss = bossBuilder;
    if (data.type == RoomType.boss && construirBoss != null) {
      final boss = construirBoss(position + Vector2(width / 2, height / 2 - 24));
      if (boss != null) {
        activeEnemies.add(boss);
        parent?.add(boss);
        return;
      }
      // Boss nulo (nada pendente pra desbloquear): cai no spawn normal.
    }

    int count = 2 + _random.nextInt(3);
    
    for (int i = 0; i < count; i++) {
      double px = 0;
      double py = 0;
      bool validPosition = false;
      int attempts = 0; 

      while (!validPosition && attempts < 30) {
        px = 48 + _random.nextInt(7) * 16.0;
        py = 48 + _random.nextInt(7) * 16.0;

        Rect enemyRect = Rect.fromLTWH(px, py, 16, 16);
        validPosition = true;

        for (var child in children) {
          if (child is Obstacle) {
            if (child.toRect().overlaps(enemyRect)) {
              validPosition = false; 
              break;
            }
          }
        }
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

    final String pathWall = 'tileset/wall.png';       
    final String pathCorner = 'tileset/wallQuina.png'; 

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

          String spriteToUse = '';
          double rotation = 0.0;

          if (isTop && isLeft)        { spriteToUse = pathCorner; rotation = 0; }
          else if (isTop && isRight)    { spriteToUse = pathCorner; rotation = math.pi / 2; }
          else if (isBottom && isRight) { spriteToUse = pathCorner; rotation = math.pi; }
          else if (isBottom && isLeft)  { spriteToUse = pathCorner; rotation = 3 * math.pi / 2; }
          else if (isTop)    { spriteToUse = pathWall; rotation = math.pi / 2; }
          else if (isBottom) { spriteToUse = pathWall; rotation = 3 * math.pi / 2; }
          else if (isLeft)   { spriteToUse = pathWall; rotation = 0; }
          else if (isRight)  { spriteToUse = pathWall; rotation = math.pi; }

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
  late final Paint _roomBackgroundPaint = Paint()..color = theme.corEscura;
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