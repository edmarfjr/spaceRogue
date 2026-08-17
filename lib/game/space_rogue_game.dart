import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
//import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey, KeyDownEvent;
import 'package:spacerogue/game/components/UI/hud.dart';
import 'package:spacerogue/game/components/UI/minimap_hud.dart';
//import 'package:spacerogue/game/components/enemies/enemy.dart';
import 'package:spacerogue/game/components/map/dungeon_generator.dart';
import 'package:spacerogue/game/components/map/room_component.dart';
import 'package:spacerogue/game/components/core/palette.dart';
import 'package:spacerogue/game/components/utils/palette_swapper.dart';
import 'components/player/player.dart';
import 'package:flame/events.dart';

class SpacerogueGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  // O Mundo onde o mapa, inimigos e jogador existirão
  late final World dungeonWorld;
  
  // A câmera que vai renderizar o mundo na resolução do Game Boy
  late final CameraComponent gameCamera;

  // Joysticks
  late final JoystickComponent moveJoystick;
  late final JoystickComponent aimJoystick;

  late final Player player;
  Vector2 currentRoomIndex = Vector2.zero();

  final VoidCallback? onGameOver; 

  List<Color> colors1Level = [Palette.indigo,Palette.marromEsc];
  List<Color> colors2Level = [Palette.eggplant,Palette.chocolate];
  
  int currentLevel = 1;

  @override
  Color backgroundColor() => const Color(0xFF1E1E1E); // Cor de fundo fora do mapa

  Map loadedRooms = {};

  late Map<String, RoomData> mapData;
  late MinimapHud minimapHud;

  double freezeTmr = 0;
  double freezeTime = 0.5;

  SpacerogueGame({this.onGameOver});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    //debugMode = true;

    // 1. Inicializa o Mundo
    dungeonWorld = World();
    add(dungeonWorld); // Adiciona o mundo ao jogo

    _setupJoysticks();

    // Pré-processa a paleta dos sprites que aparecem em pleno combate.
    // Sem isso, o PRIMEIRO tiro / explosão / morte de inimigo gerava uma
    // textura nova em tempo de execução (travadinha na hora do disparo).
    await _preloadCombatSprites();

    player = Player(moveJoystick: moveJoystick, aimJoystick: aimJoystick);
    player.onDeath = onGameOver;
    player.position = Vector2(RoomComponent.roomWidth / 2, RoomComponent.roomHeight / 2);
    dungeonWorld.add(player);

    final generator = DungeonGenerator(maxRooms: 12); // Gera uma dungeon com 12 salas
    mapData = generator.generate();

    // Percorre todos os dados de salas criados pelo algoritmo
    for (var roomData in mapData.values) {
      // Cria o componente visual e o adiciona ao mundo
      final room = RoomComponent(roomData, player: player);
      loadedRooms['${roomData.x},${roomData.y}'] = room;
      dungeonWorld.add(room);
    }

    // 2. Configura a Câmera (Resolução Fixa: 160 x 144)
    gameCamera = CameraComponent.withFixedResolution(
      width: RoomComponent.roomWidth,
      height: RoomComponent.roomHeight,
      world: dungeonWorld,
    );
    // Movemos a câmera para focar no centro lógico (0,0) inicialmente
    final startRoomCenter = Vector2(RoomComponent.roomWidth / 2, RoomComponent.roomHeight / 2);
    
    // Posiciona a câmera e o jogador no centro da primeira sala
    gameCamera.viewfinder.position = startRoomCenter;
    add(gameCamera);

    final hud = Hud(player: player);
    gameCamera.viewport.add(hud);

    minimapHud = MinimapHud(
      mapData: mapData,
      getCurrentLogicalRoom: () {
        return Vector2(currentRoomIndex.x + 50, currentRoomIndex.y + 50);
      },
      position: Vector2(RoomComponent.roomWidth - 15, 15), 
    );
    gameCamera.viewport.add(minimapHud);
    pauseEngine();
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) { // <-- MUDOU AQUI
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      if (!overlays.isActive('MainMenu')) { 
        if (overlays.isActive('PauseMenu')) {
          overlays.remove('PauseMenu');
          resumeEngine();
        } else {
          pauseEngine();
          overlays.add('PauseMenu');
        }
      }
      return KeyEventResult.handled;
    }
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    // Garante que o minimapa e o joystick fiquem nos lugares certos se a tela girar ou mudar
    // Você pode acessar os filhos do jogo filtrando pelo tipo deles:
   // children.whereType<MinimapHud>().forEach((minimap) {
   //   minimap.position = Vector2(canvasSize.x - 40, 40);
   // });
    
    // Exemplo para o joystick caso ele esteja se perdendo:
    // moveJoystick.position = Vector2(80, canvasSize.y - 80);
  }

  Future<void> _preloadCombatSprites() async {
    await PaletteSwapper.warmUp([
      // Tiro do player (Projectile padrão)
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/tiro.png',
        lightGrayReplacement: Palette.azul,
        darkGrayReplacement: Palette.verdeEsc,
      ),
      // Tiro dos inimigos (Enemy.bltImg padrão)
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/tiro2.png',
        lightGrayReplacement: Palette.vermelho,
        darkGrayReplacement: Palette.laranja,
      ),
      // Bomba
      PaletteSwapper.createSwappedImage(
        imagePath: 'projeteis/bomb.png',
        lightGrayReplacement: Palette.indigo,
        darkGrayReplacement: Palette.azulEsc,
      ),
      // Efeito de morte de inimigo
      PaletteSwapper.createSwappedImage(
        imagePath: 'effects/enemy_death.png',
        lightGrayReplacement: Palette.indigo,
        darkGrayReplacement: Palette.cinzaEsc,
        whiteReplacement: Palette.branco,
      ),
      // Drops de vida
      PaletteSwapper.createSwappedImage(
        imagePath: 'items/heartHalf.png',
        lightGrayReplacement: Palette.vermelho,
        darkGrayReplacement: Palette.roxoEsc,
      ),
      // Drop de bomba
      PaletteSwapper.createSwappedImage(
        imagePath: 'items/bomb.png',
        lightGrayReplacement: Palette.indigo,
        darkGrayReplacement: Palette.azulEsc,
      ),
    ]);
  }

  void _setupJoysticks() {
    // Estilo dos botões
    final knobPaint = BasicPalette.lightGray.withAlpha(200).paint();
    final bgPaint = BasicPalette.black.withAlpha(100).paint();

    // Joystick Esquerdo (Movimento)
    moveJoystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: bgPaint),
      // Posiciona no canto inferior esquerdo (na área fora da câmera de 160x144)
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );

    // Joystick Direito (Mira/Tiro)
    aimJoystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: bgPaint),
      // Posiciona no canto inferior direito
      margin: const EdgeInsets.only(right: 40, bottom: 40),
    );

    // Adicionamos os joysticks DIRETAMENTE ao jogo, e não ao World.
    // Isso garante que eles sejam tratados como HUD (Interface) e 
    // não sofram o zoom/escala da resolução de 160x144.
    add(moveJoystick);
    add(aimJoystick);
  }

  @override
  void update(double dt) {
    if (freezeTmr > 0) {
      freezeTmr -= dt;
      return;
    }
    super.update(dt);
    _checkCameraTransition();
  }
// NOVO MÉTODO: Limpa e recria a fase!
  void nextLevel() {
    // 1. LIMPEZA TOTAL (O "faxineiro")
    // Remove salas velhas, tiros perdidos, itens no chão... tudo, MENOS o jogador!
    for (var child in dungeonWorld.children) {
      if (child != player) {
        child.removeFromParent();
      }
    }
    loadedRooms.clear();

    // 2. GERAÇÃO DE NOVO MAPA
    // Você pode até aumentar o maxRooms a cada nível se quiser um desafio maior!
    final generator = DungeonGenerator(maxRooms: 12);
    mapData = generator.generate();

    for (var roomData in mapData.values) {
      final room = RoomComponent(roomData, player: player);
      loadedRooms['${roomData.x},${roomData.y}'] = room;
      dungeonWorld.add(room);
    }

    // 3. REPOSICIONAMENTO DO JOGADOR E CÂMERA
    // Volta o jogador para o centro lógico da fase (Sala Inicial)
    player.position = Vector2(RoomComponent.roomWidth / 2, RoomComponent.roomHeight / 2);
    currentRoomIndex = Vector2.zero();
    
    // Dá um "corte seco" na câmera de volta para o início
    gameCamera.viewfinder.position = Vector2(RoomComponent.roomWidth / 2, RoomComponent.roomHeight / 2);

    // 4. ATUALIZA O MINIMAPA
    // Entrega o novo mapa para a HUD e limpa o contorno antigo
    minimapHud.mapData = mapData;
  }

  void resetGame() {
    // 1. Você pode chamar a sua função de recriar a sala (aquela "Limpa e recria a fase!")
    // _clearRoom();
    // _generateNewRoom();
    
    // 2. Reseta a vida, posição e bombas do jogador
    player.currentHealth = player.maxHealth;
    player.bombsAmount = 3;
    player.position = Vector2(size.x / 2, size.y / 2); // Coloca no centro
    
    // 3. E garante que o jogo fique parado de novo na tela inicial
    pauseEngine(); 
  }

  void _checkCameraTransition() {
    final double roomWidth = RoomComponent.roomWidth;
    final double roomHeight = RoomComponent.roomHeight;
    final double threshold = 8.0; 

    double roomLeft = currentRoomIndex.x * roomWidth;
    double roomRight = roomLeft + roomWidth;
    double roomTop = currentRoomIndex.y * roomHeight;
    double roomBottom = roomTop + roomHeight;

    int newRoomX = currentRoomIndex.x.toInt();
    int newRoomY = currentRoomIndex.y.toInt();
    bool transitioned = false;

    if (player.position.x > roomRight - threshold) {
      newRoomX++;
      transitioned = true;
    } else if (player.position.x < roomLeft + threshold) {
      newRoomX--;
      transitioned = true;
    } else if (player.position.y > roomBottom - threshold) {
      newRoomY++;
      transitioned = true;
    } else if (player.position.y < roomTop + threshold) {
      newRoomY--;
      transitioned = true;
    }

    if (transitioned) {
      player.naoMove = true;
      
      double pushDistance = 32.0; 

      if (newRoomX > currentRoomIndex.x) {
        player.position.x += pushDistance;
      } else if (newRoomX < currentRoomIndex.x) {
        player.position.x -= pushDistance;
      } else if (newRoomY > currentRoomIndex.y) {
        player.position.y += pushDistance;
      } else if (newRoomY < currentRoomIndex.y) {
        player.position.y -= pushDistance;
      }

      currentRoomIndex = Vector2(newRoomX.toDouble(), newRoomY.toDouble());

      int logicalX = newRoomX + 50;
      int logicalY = newRoomY + 50;
      loadedRooms['$logicalX,$logicalY']?.onPlayerEnter();

      Vector2 newCameraPosition = Vector2(
        (newRoomX * roomWidth) + (roomWidth / 2),
        (newRoomY * roomHeight) + (roomHeight / 2),
      );

      gameCamera.viewfinder.add(
        MoveToEffect(
          newCameraPosition,
          EffectController(duration: 0.4, curve: Curves.easeInOut),
          onComplete: () {
            player.naoMove = false;
            freezeTmr = freezeTime;
          }
        ),
      );
    }
  }
}